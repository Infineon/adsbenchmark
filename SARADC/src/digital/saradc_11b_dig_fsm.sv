`timescale 1ns/1ns
// Disclaimer:
// THIS FILE IS PROVIDED AS IS AND WITH:
// (A) NO WARRANTY OF ANY KIND, express, implied or statutory, including any implied warranties of merchantability, fitness for a particular purpose and noninfringement, which  Infineon disclaims to the maximum extent permitted by applicable law; and
// (B) NO INDEMNIFICATION FOR INFRINGEMENT OF INTELLECTUAL PROPERTY RIGHTS.
// (C) LIMITATION OF LIABILITY: IN NO EVENT SHALL INFINEON BE LIABLE FOR ANY DIRECT, INDIRECT, SPECIAL, INCIDENTAL, OR CONSEQUENTIAL DAMAGES (INCLUDING LOST PROFITS OR SAVINGS) WHATSOEVER, WHETHER BASED ON CONTRACT, TORT OR ANY OTHER LEGAL THEORY, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGES.
// © 2020 Infineon Technologies AG. All rights reserved.

// Note:
// The CMOS transistor models used, were freely available models downloaded from: http://ptm.asu.edu.
// The bipolar transistor models are from: The Development of Bipolar Log-Domain Filters in a Standard CMOS Process, G. D. Duerden, G. W. Roberts, M. J. Deen, 2001

// Release:
// version 1.0

//`uselib lib=ipdb_common_cell_lib

module saradc_11b_dig_fsm
  #
  (
    N_CHANNELS   = 16,
    N_CONV_BITS  = 11,
    N_TRACK_BITS = 1,
    N_OVERS_BITS = 2,
    SAR_MSB      = 12,
    CAL_MSB      = 5,
    TRACK_MSB    = 4
  )
  (
    input                           clk,
    input                           nres,
    saradc_11b_dig_mackerel_if.fsm mackerel,

    // from startup module
    input enable_conv_i,
    input enable_fsms_i,
    input su_ocs_high_i,

    // ADIF
    input                         comp_i,
    input        [SAR_MSB:0]      sar_i,
    input        [TRACK_MSB:0]    track_i,
    output logic [CAL_MSB:0]      cal_o,
    output logic                  comp_res_o,
    output logic [SAR_MSB+1:0]    din_n_o,
    output logic                  en_vain_lv_o,
    output logic                  ocs_o,
    output logic                  ref_o,
    output logic [N_CHANNELS-1:0] sample_ch_o,
    output logic                  sar_res_o,
    output logic [2:0]            sesp_del_o,
    output logic                  set_sar_o,
    output logic                  set_track_o,
    output logic                  track_res_o,
    output logic [TRACK_MSB+1:0]  trackin_n_o,

    // other
    output logic sar_clk_enable_o,
    output logic scab_clk_enable_o,

    // startup handshake
    input        sucal_i,
    output logic sucal_done_o
  );


  // use package instead of *.svh files
  import saradc_11b_pkg::*;

  function logic [2:0] lfsrana2sespdel;
    input logic [1:0] lfsrana;
    begin
      lfsrana2sespdel = '0;
      case (lfsrana)
        2'd0 : lfsrana2sespdel = 3'b000; // no delay
        2'd1 : lfsrana2sespdel = 3'b001; // min delay
        2'd2 : lfsrana2sespdel = 3'b010; // medium delay
        2'd3 : lfsrana2sespdel = 3'b100; // max delay
      endcase
    end
  endfunction

  // localparams etc. ----------------------------------------------------------

  localparam REF_IDLE = 1'b1;

  localparam CONV_MSB = N_CONV_BITS -1; // MSB of adc without tracking or oversampling

  // cal

  localparam                    CAL_RAM_MAX = 0;                    // last index of cal_ram (depending on number of calibration types)
  localparam        [CAL_MSB:0] CAL_ZERO    = (1 << CAL_MSB);
  localparam signed [CAL_MSB:0] OFFSET_MIN  = -(2**CAL_MSB - 1);
  localparam        [CAL_MSB:0] OFFSET_MAX  = (2**CAL_MSB - 1);
  //localparam        [CAL_MSB:0] CAL_MIN     = {CAL_MSB{1'b0}};
  localparam        [CAL_MSB:0] CAL_MIN     = CAL_ZERO + OFFSET_MIN;//{CAL_MSB{1'b0}};
  localparam        [CAL_MSB:0] CAL_MAX     = CAL_ZERO + OFFSET_MAX;

  // track

  localparam TRACKIN_N_RES = {2'b00, {TRACK_MSB{1'b1}}}; // middle value


  // pc mux --------------------------------------------------------------------

  logic       pcm_msb_en4conv ;
  logic       pcm_msb_en4fcomp ;
  logic       pcm_msb_en4pcal ;
  logic [1:0] pcm_msb_scal_cfg ;

  always_comb pcm_msb_en4conv = mackerel.tst_dig_msb_sel ? mackerel.tst_dig_msb_en4conv : PC_MSB_EN4CONV ;
  always_comb pcm_msb_en4fcomp = mackerel.tst_dig_msb_sel ? mackerel.tst_dig_msb_en4fcomp : PC_MSB_EN4FCOMP ;
  always_comb pcm_msb_en4pcal = mackerel.tst_dig_msb_sel ? mackerel.tst_dig_msb_en4pcal : PC_MSB_EN4PCAL ;
  always_comb pcm_msb_scal_cfg = mackerel.tst_dig_msb_sel ? mackerel.tst_dig_msb_scal_cfg : PC_MSB_SCAL_CFG ;


  // sample_time etc. ----------------------------------------------------------

  logic [FSM_COUNT_MSB-1:0] ocs_time;

  always_comb
  begin
    ocs_time = '0;
    // Check if sampling time > 1, otherwise underflow occurs for stc = 1
    if (PC_DEFAULT_ST[int'(mackerel.chnr)] > 8'd1) // cast to integer necessary to avoid xcelium simulator error
    begin // conversion sampling time
      case (mackerel.stc)
        2'd0 : ocs_time = PC_DEFAULT_ST[mackerel.chnr] - 1;
        2'd1 : ocs_time = (PC_DEFAULT_ST[mackerel.chnr] >> 1) - 1; // 1/2 default
        2'd2 : ocs_time = (PC_DEFAULT_ST[mackerel.chnr] << 1) - 1; // 2 * default
        2'd3 : ocs_time = (PC_DEFAULT_ST[mackerel.chnr] << 2) - 1; // 4 * default
      endcase
      if(mackerel.sesp)
      begin
        if(mackerel.tst_dig_sesp_dig_spread_short)
        begin
          ocs_time = ocs_time + 8;
        end
        else
        begin
          ocs_time = ocs_time + 16;
        end
      end

    end
  end


  // oversampling --------------------------------------------------------------

  logic [1:0]          overs_cfg_act;    // latched config in idle state
  logic [3:0]          overs_cnt_reload; // max 15
  logic [3:0]          overs_cnt;        // fsm
  logic [CONV_MSB+4:0] overs_result;     // fsm, up to 16 times max. result_ext_sat ==> +4

  always_comb
  begin
    overs_cnt_reload = '0; // 1 x sampling
    case (mackerel.overs_cfg) // overs_cnt_reload is only loaded in idle state
      2'd1 : overs_cnt_reload = 4'd1; // 2 x sampling
      2'd2 : overs_cnt_reload = 4'd3; //  4 x sampling
      2'd3 : overs_cnt_reload = 4'd7; //  8 x sampling
    endcase
  end

  // sesp control --------------------------------------------------------------

  logic       lfsr_enable;
  logic [5:0] lfsr_val;

  always_comb lfsr_enable = mackerel.start_adc & mackerel.sesp;

  saradc_11b_dig_lfsr6 lfsr6_inst(
    .clk      (clk        ),
    .nres     (nres       ),
    .enable_i (lfsr_enable),
    .val_o    (lfsr_val   )
  );

  logic [1:0] lfsr_val_ana;
  logic [3:0] lfsr_val_dig;

  always_comb
  begin
    lfsr_val_ana = lfsr_val[5:4]; // intentionally different than sh
    lfsr_val_dig = lfsr_val[3:0]; // not to have the same sequence
    if (mackerel.tst_dig_sesp_ana_del_off)
    begin
      lfsr_val_ana = '0;
    end
    if (mackerel.tst_dig_sesp_dig_spread_short)
    begin
      lfsr_val_dig[3] = 1'b0;
    end
  end

  logic [2:0] sesp_del_val;

  always_comb sesp_del_val = lfsrana2sespdel(lfsr_val_ana);

  // dithering factor (for oversampling) -------------------------------

  logic        [9:0]       dither_lfsr_val;
  logic signed [CAL_MSB:0] dither_val;

  logic dither_lfsr_enable;
  logic ocs_del;
  logic ocs_re;

  // rising edge detection on ocs
  always_ff @(negedge nres or posedge clk)
  begin
    if (!nres)
    begin
      ocs_del <= 1'b0;
    end
    else
    begin
      ocs_del <= ocs_o;
    end
  end

  always_comb ocs_re <= ocs_o & !ocs_del;

  always_comb dither_lfsr_enable = enable_fsms_i && overs_cfg_act && ocs_re && !mackerel.eoc;

  saradc_11b_dig_lfsr10 lfsr10_inst(
    .clk      (clk               ),
    .nres     (nres              ),
    .enable_i (dither_lfsr_enable),
    .val_o    (dither_lfsr_val   )
  );

  // assign dither_lfsr_val to dither_val
  // TODO: check dithering (transfercurve)
  always_comb
  begin
    dither_val = 6'd0; //default 0
    //        case (mackerel.dither_cfg)
    //            2'd0 : dither_val = 5'd0;                                             // no dithering
    //            2'd1 : dither_val = {{3{dither_lfsr_val[1]}} , dither_lfsr_val[1:0]}; //2 lfsr bit (sign extended)
    //            2'd2 : dither_val = {{2{dither_lfsr_val[2]}} , dither_lfsr_val[2:0]}; //3 lfsr bit (sign extended)
    //            2'd3 : dither_val = {{dither_lfsr_val[3]} ,dither_lfsr_val[3:0]} ;    //4 lfsr bit
    //        endcase
    case (mackerel.dither_cfg)
      2'd0 : dither_val = 5'd0; // no dithering
      2'd1 :
      begin
        if (!dither_lfsr_val[1:0])
        begin
          dither_val = 6'b000010; // replace 0 with 2
        end
        else
        begin
          dither_val = {{4{dither_lfsr_val[1]}} , dither_lfsr_val[1:0]};//2 lfsr bit (sign extended)
        end
      end
      2'd2 :
      begin
        if (!dither_lfsr_val[2:0])
        begin
          dither_val = 6'b000100; // replace 0 with 4
        end
        else
        begin
          dither_val = {{3{dither_lfsr_val[2]}} , dither_lfsr_val[2:0]}; //3 lfsr bit (sign extended)
        end
      end
      2'd3 :
      begin
        if (!dither_lfsr_val[3:0])
        begin
          dither_val = 6'b001000; // replace 0 with 8
        end
        else
        begin
          dither_val = {{2{dither_lfsr_val[3]}} ,dither_lfsr_val[3:0]} ; //4 lfsr bit
        end
      end
    endcase
  end
  // basic ---------------------------------------------------------------------

  logic [FSM_COUNT_MSB-1:0] counter; // max-value 104 (max sample time - 1)

  logic [CONV_MSB+1:0] result_ext;
  logic [CONV_MSB :0]  result_ext_sat;

  always_comb result_ext_sat = result_ext[CONV_MSB+1] ? '1 : result_ext[CONV_MSB:0]; // saturate to 11 bit

  logic [SAR_MSB:0] sar_raw_dig; // for test

  logic comp_cfg_act;


  // tracking ------------------------------------------------------------------

  logic        [2:0]          track_cnt_reload; // 0, 2, or 6
  logic        [2:0]          track_cnt;        // fsm
  logic signed [TRACK_MSB:0]  track_dig;        // fsm
  logic        [CONV_MSB+2:0] track_add;
  logic        [CONV_MSB+4:0] track_result;     // fsm, up to 8 times max. result_ext_sat ==> +3 and track_i ==> +4
  logic        [CONV_MSB+3:0] track_result_sat;

  // calibration ---------------------------------------------------------------

  logic sucal_run;

  logic [6:0] cal_sample_time; // max-value = 127
  logic [6:0] cal_ref_time;

  always_comb
  begin
    cal_sample_time = PC_STC_CAL[int'(mackerel.stc_cal)] - 1; // cast to integer necessary to avoid xcelium simulator error
    if (sucal_run)
    begin
      cal_sample_time += PC_STC_CAL[mackerel.stc_cal];
    end
  end

  always_comb
  begin
    cal_ref_time = cal_sample_time[6:1] + 1; // 1/2*sample time
  end

  logic cal_pcal_none;

  always_comb cal_pcal_none = !mackerel.epcal;

  logic signed [CAL_MSB:0] cal_ram [CAL_RAM_MAX:0]; // 0: offset calibration value

  logic [CAL_MSB-1:0] cal_step;  // 5-bit cal --> 32 cal. sequences in sucal
  logic               cal_result;

  logic cal_test_write_edge; // test

  // calibration filter
  logic [6:0] cal_filter_reload;
  logic [6:0] pcal_filter_runs;
  logic [5:0] cal_filter_thres;
  logic [5:0] cal_filter_result;
  logic [5:0] pcal_filter_result;
  logic       pcal_filter_update;
  logic [1:0] cal_filter_prev_val;


  always_comb
  begin
    cal_filter_reload = '0; cal_filter_thres = 6'd1;// single filter sample
    case (mackerel.tst_dig_cal_filter_cfg)
      2'd1 :
      begin cal_filter_reload = 7'd3; cal_filter_thres = 6'd2; end // 4 filter samples
      2'd2 :
      begin cal_filter_reload = 7'd7; cal_filter_thres = 6'd4; end // 8 filter samples
      2'd3 :
      begin cal_filter_reload = 7'd31;cal_filter_thres = 6'd16; end // 32 filter samples
    endcase
  end

  // fsm -----------------------------------------------------------------------

  enum {
    ST_STARTUP,
    ST_IDLE,
    ST_SAMPLE,
    ST_SAMPLE_DEL,
    ST_WAIT_CONV_COMP,
    ST_CONV_MSB,
    ST_CONV,
    ST_CONV_LAST1,
    ST_CONV_LAST2,
    ST_COMP_MSB,
    ST_COMP,
    ST_COMP_LAST1,
    ST_COMP_LAST2,
    ST_CAL_WAIT,
    ST_CAL_SAMPLE,
    ST_CAL_COMP_MSB,
    ST_CAL_COMP,
    ST_CAL_COMP2,
    ST_CAL_COMP_LAST1,
    ST_CAL_COMP_LAST2
  } state_e;

  logic signed [CAL_MSB:0] cal_ovf_tmp;

  // TODO: check if all states are necessary in if condition
  // overflow check for calibration
  always_comb
  begin
    if((state_e == ST_IDLE || state_e == ST_SAMPLE_DEL || state_e == ST_CONV_LAST2 || state_e == ST_COMP_LAST2) && (|mackerel.overs_cfg))
    begin
      cal_ovf_tmp = cal_ram[0] + dither_val;
    end
    else
    begin
      cal_ovf_tmp = 6'b0;
    end
  end

  task GO_SAMPLE;
    begin

      cal_filter_prev_val <= mackerel.tst_dig_cal_filter_cfg;

      if ({27'b0,mackerel.chnr} < N_CHANNELS)
      begin // valid channel
        sample_ch_o <= 1'd1 << mackerel.chnr;
        if (PC_LV_CHANNELS[mackerel.chnr])
        begin // LV
          en_vain_lv_o <= 1'b1;
        end
      end


      // common for all channels
      ref_o     <= 1'b0;
      cal_o     <= CAL_ZERO - cal_ram[0] ; // offset compensation
      ocs_o     <= 1'b1;
      set_sar_o <= 1'b1;


      // for oversampling
      // apply dithering only for oversampling, if enabled
      if (|mackerel.overs_cfg)
      begin
        if ((~cal_ovf_tmp[CAL_MSB] && ~cal_ram[0][CAL_MSB]) ||
            (cal_ovf_tmp[CAL_MSB] && dither_val[CAL_MSB]) ||
            (cal_ram[0][CAL_MSB] && ~dither_val[CAL_MSB])) // overflow protection
        begin
          if (((CAL_ZERO - cal_ram[0] - dither_val) <= CAL_MAX) &&
              ((CAL_ZERO - cal_ram[0] - dither_val) >= CAL_MIN)) // boundary (-31/+31) protection
          begin
            cal_o <= CAL_ZERO - cal_ram[0] - dither_val;
          end
        end
      end


      // common for all channels and comp_nosamp
      if ((8'b1 >= ocs_time) || (mackerel.sesp && ({4'd0,(lfsr_val_dig + 4'd2)} >= ocs_time)))
      begin
        scab_clk_enable_o <= 1'b0;
      end
      counter <= ocs_time;
      state_e <= ST_SAMPLE;
    end
  endtask

  task GO_CAL_WAIT;
    begin
      scab_clk_enable_o <= 1'b0;
      state_e           <= ST_CAL_WAIT;
    end
  endtask

  task EOC;
    begin
      mackerel.busy <= 1'b0;
      if (comp_cfg_act)
      begin
        mackerel.result <= (result_ext_sat != '0) ? '1 : '0;
      end
      else if (|overs_cfg_act)
      begin // oversampling (no tracking possible)
        case (overs_cfg_act)
          2'd1 : mackerel.result   <= ((overs_result + result_ext_sat) >> 0);  //  2 x sampling
          2'd2 : mackerel.result   <= ((overs_result + result_ext_sat) >> 1);  //  4 x sampling
          2'd3 : mackerel.result   <= ((overs_result + result_ext_sat) >> 2);  //  8 x sampling
          default: mackerel.result <= {result_ext_sat, {N_OVERS_BITS{1'b0}} }; // invalid state
        endcase
      end
      else
      begin // no oversampling
        if (N_OVERS_BITS > N_TRACK_BITS)
        begin
          if (N_OVERS_BITS > 1)
          begin
            mackerel.result <= ({result_ext_sat, {N_OVERS_BITS{1'b0}} }) >> (N_OVERS_BITS - 1);
          end
          else
          begin
            mackerel.result <= ({result_ext_sat, {N_OVERS_BITS{1'b0}} });
          end
        end
        else
        begin
          if (N_TRACK_BITS > 1)
          begin
            mackerel.result <=  {result_ext_sat, {N_TRACK_BITS{1'b0}} } >> (N_TRACK_BITS - 2'd1);
          end
          else if (N_TRACK_BITS == 0 && N_CONV_BITS == 11)
          begin
            mackerel.result <= {result_ext_sat, {N_TRACK_BITS{1'b0}} } << 1;
          end
          else
          begin
            mackerel.result <= {result_ext_sat, {N_TRACK_BITS{1'b0}} };
          end
        end
      end

      ocs_o <= 1'b1;
      mackerel.eoc <= 1'b1;
      state_e <= ST_IDLE;
    end
  endtask

  always_ff @(negedge nres or posedge clk)
  begin
    if (!nres)
    begin
      // mackerel
      mackerel.busy          <= '0;
      mackerel.eoc           <= '0;
      mackerel.eoc_pre       <= '0;
      mackerel.result        <= '0;
      // adif
      cal_o                  <= CAL_ZERO;
      comp_res_o             <= '1;
      din_n_o                <= '1;
      en_vain_lv_o           <= '0;
      ocs_o                  <= '0;
      ref_o                  <= '0; // startup behavior
      sample_ch_o            <= '0; // startup behavior
      sar_res_o              <= '1;
      sesp_del_o             <= '0;
      set_sar_o              <= '0;
      track_res_o            <= '1;
      set_track_o            <= '1;
      trackin_n_o            <= TRACKIN_N_RES;
      // other
      sar_clk_enable_o       <= '0;
      scab_clk_enable_o      <= '1;
      sucal_done_o           <= '0;
      // internal
      cal_filter_result      <= '0;
      cal_ram                <= '{CAL_RAM_MAX+1{'0}};
      cal_result             <= '0;
      cal_step               <= '0;
      comp_cfg_act           <= '0;
      counter                <= '0;
      overs_cfg_act          <= '0;
      overs_cnt              <= '0;
      overs_result           <= '0;
      pcal_filter_result     <= '0;
      pcal_filter_runs       <= '0;
      pcal_filter_update     <= '0;
      result_ext             <= '0;
      sar_raw_dig            <= '0;
      sucal_run              <= '0;
      track_cnt              <= '0;
      track_dig              <= '0;
      track_result           <= '0;
      cal_filter_prev_val    <= '0;
      state_e <= ST_STARTUP;
    end
    else
    begin
      mackerel.eoc     <= 1'b0;
      mackerel.eoc_pre <= 1'b0;
      sucal_done_o <= '0;

      case (state_e)

        ST_STARTUP :
        begin
          sample_ch_o <= '0;
          ref_o       <= '0;
          ocs_o       <= su_ocs_high_i;
          if (enable_fsms_i)
          begin
            ref_o    <= REF_IDLE;
            state_e  <= ST_IDLE;
          end
        end

        ST_IDLE :
        begin
          ocs_o <= 1'b0;

          if(cal_filter_prev_val != mackerel.tst_dig_cal_filter_cfg)
          begin
            pcal_filter_result <= '0;
            pcal_filter_runs   <= '0;
          end

          // disable
          if (!enable_fsms_i)
          begin //TODO: check disable signals
            sample_ch_o        <= '0;
            ref_o              <= 1'b0;
            pcal_filter_runs   <= '0;
            pcal_filter_result <= '0;
            state_e            <= ST_STARTUP;
          end
          // sucal
          else if (sucal_i)
          begin
            sucal_run <= 1'b1;
            cal_step  <= '0;
            GO_CAL_WAIT;
          end
          // conversion
          else if (enable_conv_i && mackerel.start_adc)
          begin
            mackerel.busy <= 1'b1;

            // latch configuration (oversampling is dominant)
            comp_cfg_act  <= mackerel.comp_en;
            overs_cfg_act <= mackerel.overs_cfg;
            overs_cnt     <= overs_cnt_reload;
            overs_result  <= '0;

            if ({27'd0,mackerel.chnr} < N_CHANNELS)
            begin // LV
              if (PC_LV_CHANNELS[mackerel.chnr])
              begin // (LV)
                if (PC_SUPPL_CHANNELS[mackerel.chnr])
                  din_n_o <= {1'b0, ~cv_lv_gain[1]}; //supplementary channels (hard coded 3/4 gain)
                else
                  din_n_o <= {1'b0, ~cv_lv_gain[mackerel.lv_gain]};
              end
              state_e <= ST_SAMPLE_DEL;
            end
            else
            begin // non-existent
              GO_SAMPLE();
            end
          end
        end

        ST_SAMPLE_DEL :
        begin
          GO_SAMPLE();
        end

        ST_SAMPLE :
        begin
          // sesp dig
          if (mackerel.sesp && ((counter - 8'd1) <= {4'd0,lfsr_val_dig}))
          begin
            ocs_o <= 1'b0;
          end
          // sesp ana (don't set if ocs_o goes low already ==> "else if")
          else if (mackerel.sesp && (sesp_del_o != sesp_del_val))
          begin
            sesp_del_o <= sesp_del_val;
          end
          // scab
          if ((8'd2 >= counter) || (mackerel.sesp && ((counter - 8'd3) <= {4'd0,lfsr_val_dig})))
          begin
            scab_clk_enable_o <= 1'b0;
          end

          // finish
          if (!counter)
          begin
            sample_ch_o <= '0;
            if (PC_LV_CHANNELS[mackerel.chnr])
            begin // LV
              en_vain_lv_o <= '0;
            end
            cal_o      <= CAL_ZERO;
            ocs_o      <= 1'b0;
            sesp_del_o <= '0;
            ref_o      <= 1'b1;
            if (mackerel.comp_en)
            begin // fast compare
              comp_res_o <= 1'b0;
              set_sar_o  <= 1'b1;
              din_n_o    <= {1'b0, ~mackerel.comp_val};
            end
            else
            begin // conversion
              sar_res_o <= 1'b0;
              set_sar_o <= 1'b0;
              din_n_o   <= {1'b0, {CAP_MSB+1{1'b1}}};
            end

            state_e <= ST_WAIT_CONV_COMP;
          end
          else
          begin
            counter <= counter - 1;
          end
        end

        ST_WAIT_CONV_COMP :
        begin
          counter     <= CAP_MSB;
          result_ext  <= '0;

          if (mackerel.comp_en)
          begin // fast compare
            sar_clk_enable_o <= pcm_msb_en4fcomp ? 1'b0 : 1'b1 ;
            state_e          <= pcm_msb_en4fcomp ? ST_COMP_MSB : ST_COMP ;
          end
          else
          begin // conversion
            sar_clk_enable_o <= pcm_msb_en4conv ? 1'b0 : 1'b1 ;
            state_e          <= pcm_msb_en4conv ? ST_CONV_MSB : ST_CONV ;
          end
        end

        ///// conversion /////

        ST_CONV_MSB :
        begin
          sar_clk_enable_o <= 1'b1;
          state_e          <= ST_CONV;
        end

        ST_CONV :
        begin
          if ({24'd0,counter} != CAP_MSB)
          begin
            if (sar_i[counter + 1])
            begin
              result_ext <= result_ext + cap_val[counter + 8'd1];
            end
          end
          din_n_o <= {1'b1, din_n_o[SAR_MSB+1:1]};
          if (!counter)
          begin
            mackerel.eoc_pre <=!overs_cnt & cal_pcal_none;
            sar_clk_enable_o  <= 1'b0;
            scab_clk_enable_o <= 1'b1;
            state_e           <= ST_CONV_LAST1;
          end
          else
          begin
            counter <= counter - 8'd1;
          end
        end

        ST_CONV_LAST1 :
        begin
          en_vain_lv_o <= '0; // LV
          cal_o <= CAL_ZERO;
          ref_o <= REF_IDLE;
          din_n_o <= '1;
          if (sar_i[0])
          begin
            result_ext <= result_ext + cap_val[0];
          end
          sar_raw_dig <= sar_i;
          state_e <= ST_CONV_LAST2;
        end

        ST_CONV_LAST2 :
        begin
			sar_res_o <= 1'b1;
			if (!overs_cnt)
			begin
			  if (cal_pcal_none)
			  begin
				EOC;
			  end
			  else
			  begin
				GO_CAL_WAIT;
			  end
			end
			else
			begin
			  overs_cnt    <= overs_cnt - 1;
			  overs_result <= overs_result + result_ext_sat;
			  if (PC_LV_CHANNELS[mackerel.chnr])
			  begin // (LV)
				if (PC_SUPPL_CHANNELS[mackerel.chnr])
				  din_n_o <= {1'b0, ~cv_lv_gain[1]}; //supplementary channels (hard coded 3/4 gain)
				else
				  din_n_o <= {1'b0, ~cv_lv_gain[mackerel.lv_gain]};
				state_e <= ST_SAMPLE_DEL;
			  end
			  else
			  begin // invalid channel
				GO_SAMPLE;
			  end
			end
        end

        ///// fast compare /////

        ST_COMP_MSB :
        begin
          sar_clk_enable_o <= 1'b1;
          state_e          <= ST_COMP;
        end

        ST_COMP :
        begin
          mackerel.eoc_pre  <= (comp_cfg_act|| cal_pcal_none);
          sar_clk_enable_o  <= 1'b0;
          scab_clk_enable_o <= 1'b1;
          state_e           <= ST_COMP_LAST1;
        end

        ST_COMP_LAST1 :
        begin
          ref_o      <= REF_IDLE;
          set_sar_o  <= 1'b0;
          din_n_o    <= '1;
          result_ext <= {{(CAP_MSB+1){1'b0}}, comp_i};
          state_e    <= ST_COMP_LAST2;
        end

        ST_COMP_LAST2 :
        begin
          comp_res_o <= 1'b1;
          if (comp_cfg_act || cal_pcal_none)
          begin
            EOC;
          end
        end
        
        ///// calibration /////

        ST_CAL_WAIT :
        begin
          ocs_o             <= 1'b1;
          cal_o             <= CAL_ZERO - cal_ram[0];
          set_sar_o         <= 1'b1;
          ref_o             <= 1'b0;
          cal_filter_result <= '0;
          din_n_o           <= {1'b0, {CAP_MSB+1{1'b1}}};
          counter           <= cal_sample_time;
          state_e           <= ST_CAL_SAMPLE;
        end

        ST_CAL_SAMPLE :
        begin
          if (!counter)
          begin
            ocs_o      <= 1'b0;
            ref_o      <= 1'b1;
            comp_res_o <= 1'b0;
            cal_o      <= CAL_ZERO;
            if ((sucal_run && pcm_msb_scal_cfg) || (!sucal_run && pcm_msb_en4pcal))
            begin
              if (sucal_run)
              begin
                case (pcm_msb_scal_cfg)
                  2'd2 : counter <= 7'd2; // --> 3 cycles in ST_CAL_COMP_MSB
                  2'd3 : counter <= 7'd6; // --> 7 cycles in ST_CAL_COMP_MSB
                endcase
              end // else 1 cycle in ST_CAL_COMP_MSB
              state_e <= ST_CAL_COMP_MSB;
            end
            else
            begin
              if (sucal_run)
              begin
                counter <= cal_filter_reload;
              end
              sar_clk_enable_o <= 1'b1;
              state_e          <= ST_CAL_COMP;
            end
          end
          else
          begin
            counter <= counter - 8'd1;
            if ({1'b0,cal_ref_time} >= counter)
            begin
              ref_o <= 1'b1;
            end
          end
        end

        ST_CAL_COMP_MSB :
        begin
          if (!counter)
          begin
            if (sucal_run)
            begin
              counter <= cal_filter_reload;
            end
            sar_clk_enable_o <= 1'b1;
            state_e          <= ST_CAL_COMP;
          end
          else
          begin
            counter <= counter - 1;
          end
        end

        ST_CAL_COMP :
        begin
          if (!counter)
          begin
            mackerel.eoc_pre  <= !sucal_run;
            sar_clk_enable_o  <= 1'b0;
            scab_clk_enable_o <= 1'b1;
            state_e           <= ST_CAL_COMP_LAST1;
          end
          else
          begin
            state_e          <= ST_CAL_COMP2;
            sar_clk_enable_o <= 1'b0;
          end
        end

        ST_CAL_COMP2 :
        begin
          counter           <= counter - 1;
          cal_filter_result <= cal_filter_result + comp_i;
          sar_clk_enable_o  <= 1'b1;
          state_e           <= ST_CAL_COMP;
        end

        ST_CAL_COMP_LAST1 :
        begin

          ref_o     <= REF_IDLE;
          cal_o     <= CAL_ZERO;
          set_sar_o <= 1'b0;
          din_n_o   <= '1;
          if (!mackerel.tst_dig_cal_filter_cfg)
          begin
            cal_result <= comp_i;
          end
          else
          begin
            if (sucal_run )
            begin
              if ((cal_filter_result + comp_i) >= cal_filter_thres)
              begin
                cal_result <= 1'b1;
              end
              else
              begin
                cal_result <= 1'b0;
              end
            end
            else
            begin //pcal
              if (pcal_filter_runs >= cal_filter_reload)
              begin
                if ((pcal_filter_result + comp_i) >= cal_filter_thres)
                begin
                  cal_result <= 1'b1;
                end
                else
                begin
                  cal_result <= 1'b0;
                end
                pcal_filter_runs   <= '0;
                pcal_filter_result <= '0;
                pcal_filter_update <= 1'b1;
              end
              else
              begin
                pcal_filter_result <= pcal_filter_result + comp_i;
                pcal_filter_runs   <= pcal_filter_runs + 1;
              end
            end
          end
          state_e <= ST_CAL_COMP_LAST2;
        end

        ST_CAL_COMP_LAST2 :
        begin
          comp_res_o <= 1'b1;

          if (sucal_run || !mackerel.tst_dig_cal_filter_cfg || pcal_filter_update )
          begin
            if (cal_result)
            begin
              if (OFFSET_MAX != cal_ram[0])
              begin
                cal_ram[0] <= cal_ram[0] + 1;
              end
            end
            else
            begin
              if (OFFSET_MIN != cal_ram[0])
              begin
                cal_ram[0] <= cal_ram[0] - 1;
              end
            end
            pcal_filter_update <= 1'b0;
          end
          cal_step <= cal_step +1;

          if (!sucal_run)
          begin // post-calibration
            EOC;
          end
          else
          begin // sucal
            if (&cal_step)
            begin // step = max
              sucal_run    <= 1'b0;
              sucal_done_o <= 1'b1;
              state_e      <= ST_IDLE;
            end
            else
            begin
              GO_CAL_WAIT;
            end
          end
        end

      endcase

      ///// writing of calibration values via tst_dig /////

      if (cal_test_write_edge)
      begin
        cal_ram[0] <= mackerel.tst_dig_cal_val;
      end


    end
  end

  // test section --------------------------------------------------------------

  // write

  logic cal_test_write_sync;

  ipdb_common_sync ipdb_common_sync_cal_write_inst(
    .clk_i     (clk                       ),
    .reset_n_i (nres                      ),
    .data_i    (mackerel.tst_dig_cal_write),
    .data_o    (cal_test_write_sync       )
  );

  logic cal_test_write_sync_del;

  always_ff @(negedge nres or posedge clk)
  begin
    if (!nres)
    begin
      cal_test_write_sync_del      <= 1'b0;
    end
    else
    begin
      cal_test_write_sync_del      <= cal_test_write_sync;
    end
  end

  always_comb cal_test_write_edge = cal_test_write_sync & !cal_test_write_sync_del;

  // read

  always_comb
  begin
    mackerel.tst_dig_out = '0;
    case (mackerel.tst_dig_sel)
      3'd0: mackerel.tst_dig_out[CAL_MSB: 0]  = cal_ram[0] ;
      3'd1: mackerel.tst_dig_out[SAR_MSB: 0]  = sar_raw_dig ;
      3'd2: mackerel.tst_dig_out[TRACK_MSB: 0]= track_dig ;
      3'd3: mackerel.tst_dig_out[19: 0]       = '0;
    endcase
  end
endmodule


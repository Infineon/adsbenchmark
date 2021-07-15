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

/**
 *
 * <h2>Digital top level</h2>
 * @author 
 */
module saradc_11b_dig_top
    import saradc_11b_pkg::*;
    (
     input clk_i,   // system clock
     input res_n_i, // async. reset

     input [CHNR_MSB:0]        chnr_i,           // mackerel
     input                     comp_en_i,        // mackerel
     input [SAR_MSB:0]         comp_val_i,       // mackerel
     input [1:0]               dither_cfg_i,     // mackerel
     input                     dscal_i,          // mackerel
     input                     epcal_i,          // mackerel
     input                     lv_gain_i,        // mackerel
     input                     mod_enable_i,     // mackerel
     input                     mod_lowsup_i ,    // mackerel
     input [1:0]               overs_cfg_i,      // mackerel
     input                     sesp_i,           // mackerel
     input                     start_adc_i,      // mackerel
     input [1:0]               stc_i,            // mackerel
     input [1:0]               stc_cal_i,        // mackerel
     input [1:0]               track_cfg_i,      // mackerel
     input [TST_DIG_IN_SIZE:0] tst_dig_i,        // mackerel
	 input                	   tst_stress_i,     // mackerel
     
     output                      busy_o,        // mackerel
     output                      eoc_pre_o,     // mackerel
     output                      eoc_o,         // mackerel
     output                      mod_ready_o,   // mackerel
     output [RESULT_MSB:0]       result_o,      // mackerel
     output [TST_DIG_OUT_SIZE:0] tst_dig_o,     // mackerel

     input               comp_i,  // adif
     input [SAR_MSB:0]   sar_i,   // adif
     input [TRACK_MSB:0] track_i, // adif

     output [CAL_MSB:0]      cal_o,                // adif
     output                  comp_res_o,           // adif
     output                  cp_clk_ldo_o,         // adif
     output [SAR_MSB+1:0]    din_n_o,              // adif
     output                  en_vain_lv_o,         // adif
     output                  enable_o,             // adif
     output                  lowsup_o,             // adif
     output                  ocs_o,                // adif
     output                  ref_o,                // adif
     output                  release_ldo_o,        // adif
     output                  sar_clk_o,            // adif
     output                  sar_res_o,            // adif
     output [N_CHANNELS-1:0] sample_ch_o,          // adif
     output                  scab_clk_o,           // adif
     output [2:0]            sesp_del_o,           // adif
     output                  set_sar_o,            // adif
     output                  set_track_o,          // adif
     output                  track_res_o,          // adif
     output [TRACK_MSB+1:0]  trackin_n_o,          // adif

     input jtag_mode_i, // jtag specific

     input         scan_enable_i, // scan
     input  [ 3:0] scan_in_i,     // scan
     output [ 3:0] scan_out_o,    // scan
     input         scan_mode_i    // scan
     );


    // ---------------------------------------------------------------------------

    logic       res_n_sync_v; // synchronized reset variable

    ipdb_common_sync_rst ipdb_common_sync_rst_inst(
                                                   .clk_i         (clk_i        ),
                                                   .reset_n_i     (res_n_i      ),
                                                   .scan_mode_i   (scan_mode_i  ),
                                                   .synch_reset_o (res_n_sync_v )
                                                   );


    // mackerel assignment -------------------------------------------------------

    saradc_11b_dig_mackerel_if #(.CHNR_MSB (CHNR_MSB),
                                  .SAR_MSB          (SAR_MSB         ),
                                  .TST_DIG_IN_SIZE  (TST_DIG_IN_SIZE ),
                                  .TST_DIG_OUT_SIZE (TST_DIG_OUT_SIZE),
                                  .RESULT_MSB       (RESULT_MSB      )
                                  )
    mackerel(clk_i, res_n_i);

    assign mackerel.mod_enable     = mod_enable_i ;
    assign mackerel.mod_lowsup     = mod_lowsup_i ;
    assign mackerel.start_adc      = start_adc_i ;
    assign mackerel.chnr           = chnr_i ;
    assign mackerel.stc            = stc_i ;
    assign mackerel.sesp           = sesp_i ;
    assign mackerel.track_cfg      = '0 ;
    assign mackerel.overs_cfg      = overs_cfg_i ;
    assign mackerel.dither_cfg     = dither_cfg_i ;
    assign mackerel.epcal          = epcal_i ;
    assign mackerel.dscal          = dscal_i ;
    assign mackerel.stc_cal        = stc_cal_i ;
    assign mackerel.lv_gain        = lv_gain_i ;
    assign mackerel.comp_en        = comp_en_i ;
    assign mackerel.comp_val       = comp_val_i ;
    assign mackerel.tst_dig_in     = tst_dig_i ;

    assign mod_ready_o = mackerel.mod_ready ;
    assign busy_o      = mackerel.busy ;
    assign result_o    = mackerel.result ;
    assign eoc_o       = mackerel.eoc ;
    assign eoc_pre_o   = mackerel.eoc_pre ;
    assign tst_dig_o   = mackerel.tst_dig_out ;

    // adif assignment -----------------------------------------------------------

    saradc_11b_dig_adif_if #(.N_CHANNELS (N_CHANNELS ),
                              .SAR_MSB    (SAR_MSB    ),
                              .CAL_MSB    (CAL_MSB    ),
                              .TRACK_MSB  (TRACK_MSB  )
                              )
    adif(clk_i, res_n_i);

    assign sample_ch_o          = adif.sample_ch ;
    assign sesp_del_o           = adif.sesp_del ;
    assign ref_o                = adif.refe ;
    assign sar_res_o            = adif.sar_res ;
    assign track_res_o          = adif.track_res ;
    assign comp_res_o           = adif.comp_res ;
    assign sar_clk_o            = adif.sar_clk ;
    assign set_sar_o            = adif.set_sar ;
    assign din_n_o              = adif.din_n ;
    assign set_track_o          = adif.set_track ;
    assign trackin_n_o          = adif.trackin_n ;
    assign cal_o                = adif.cal ;
    assign ocs_o                = adif.ocs ;
    assign enable_o             = adif.enable ;
    assign release_ldo_o        = adif.release_ldo ;
    assign en_vain_lv_o         = adif.en_vain_lv ;
    assign scab_clk_o           = adif.scab_clk ;
    assign cp_clk_ldo_o         = adif.cp_clk_ldo ;
    assign lowsup_o             = adif.lowsup ;

    assign adif.sar   = sar_i ;
    assign adif.comp  = comp_i ;
    assign adif.track = track_i ;

    // ---------------------------------------------------------------------------

    saradc_11b_dig_mackerel_if #(.CHNR_MSB (CHNR_MSB),
                                  .SAR_MSB          (SAR_MSB         ),
                                  .TST_DIG_IN_SIZE  (TST_DIG_IN_SIZE ),
                                  .TST_DIG_OUT_SIZE (TST_DIG_OUT_SIZE),
                                  .RESULT_MSB       (RESULT_MSB      )
                                  )
    mackerel_core(clk_i, res_n_i);
    // ---------------------------------------------------------------------------

    /*
     *****************************************************************************
     *                                   DIG_TOP                                 *
     *                  *****************                   *****************    *
     *                  * mackerel_sync *                   |     core      |    *
     *<=== mackerel ===>*               *<= mackerel_core =>| (fsm)         |    *
     * (mp)        (sp) *               * (mp)              | (startup)     |    *
     *                  *               *                   | (core)        |    *
     *                  *               *                   |               |    *
     *                  *****************                   *****************    *
     *                                                                           *
     *****************************************************************************
     */
    saradc_11b_dig_mackerel_sync mackerel_sync_inst(
                                                     .clk_i       (clk_i           ),
                                                     .res_n_i     (res_n_sync_v    ),
                                                     .jtag_mode_i (jtag_mode_i     ),
                                                     .mackerel_sp (mackerel.sp     ),
                                                     .mackerel_mp (mackerel_core.mp)
                                                     );
    // ---------------------------------------------------------------------------

    saradc_11b_dig_adif_if #(.N_CHANNELS (N_CHANNELS ),
                              .SAR_MSB    (SAR_MSB    ),
                              .CAL_MSB    (CAL_MSB    ),
                              .TRACK_MSB  (TRACK_MSB  )
                              )
    adif_core(clk_i, res_n_sync_v);
    // ---------------------------------------------------------------------------

    saradc_11b_dig_core #(.N_CHANNELS (N_CHANNELS ),
                           .N_CONV_BITS  (N_CONV_BITS ),
                           .N_TRACK_BITS (N_TRACK_BITS),
                           .N_OVERS_BITS (N_OVERS_BITS),
                           .SAR_MSB      (SAR_MSB     ),
                           .CAL_MSB      (CAL_MSB     ),
                           .TRACK_MSB    (TRACK_MSB   )
                           )
    dig_core_inst(
                  .clk              (clk_i                ),
                  .nres             (res_n_sync_v         ),
                  .mackerel_fsm     (mackerel_core.fsm    ),
                  .mackerel_startup (mackerel_core.startup),
                  .adif             (adif_core.mp         )
                  );
   
    // ---------------------------------------------------------------------------

    saradc_11b_dig_scanmux #(.N_CHANNELS (N_CHANNELS ),
                              .SAR_MSB     (SAR_MSB     ),
                              .CAL_MSB     (CAL_MSB     ),
                              .TRACK_MSB   (TRACK_MSB   ),
                              .LOOPBACK_EN (LOOPBACK_EN )
                              )
    scanmux_inst(
                 .scan_mode_i (scan_mode_i ),
                 .adif_test   (adif_core.sp),
                 .adif_sm     (adif.mp     )
                 );

endmodule



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

module saradc_11b_dig_mackerel_sync
    (
     input clk_i,
     input res_n_i,
     input jtag_mode_i,

     saradc_11b_dig_mackerel_if.sp mackerel_sp,
     saradc_11b_dig_mackerel_if.mp mackerel_mp
     );

    // sync + edge detection -----------------------------------------------------

    logic mod_enable_sync_v;
    logic start_adc_sync_v;

    ipdb_common_sync ipdb_common_sync_me_inst(
                                              .clk_i     (clk_i                 ),
                                              .reset_n_i (res_n_i               ),
                                              .data_i    (mackerel_sp.mod_enable),
                                              .data_o    (mod_enable_sync_v     )
                                              );

    ipdb_common_sync ipdb_common_sync_sa_inst(
                                              .clk_i     (clk_i                ),
                                              .reset_n_i (res_n_i              ),
                                              .data_i    (mackerel_sp.start_adc),
                                              .data_o    (start_adc_sync_v     )
                                              );

    logic mod_enable_muxed_v;
    logic start_adc_muxed_v;

    always_comb mod_enable_muxed_v = jtag_mode_i ? mod_enable_sync_v : mackerel_sp.mod_enable ;
    always_comb start_adc_muxed_v = jtag_mode_i ? start_adc_sync_v : mackerel_sp.start_adc ;

    logic start_adc_muxed_del_v;

    always_ff @(negedge res_n_i or posedge clk_i)
    begin
        if (!res_n_i)
        begin
            start_adc_muxed_del_v <= 1'b0;
        end
        else
        begin
            start_adc_muxed_del_v <= start_adc_muxed_v;
        end
    end

    logic start_adc_muxed_rising_v;

    always_comb start_adc_muxed_rising_v = start_adc_muxed_v & !start_adc_muxed_del_v ;

    // ass -----------------------------------------------------------------------

    assign mackerel_mp.mod_enable     = mod_enable_muxed_v ;       // [sync]
    assign mackerel_mp.start_adc      = start_adc_muxed_rising_v ; // [sync] + edge
    assign mackerel_mp.chnr           = mackerel_sp.chnr ;
    assign mackerel_mp.stc            = mackerel_sp.stc ;
    assign mackerel_mp.sesp           = mackerel_sp.sesp ;
    assign mackerel_mp.track_cfg      = mackerel_sp.track_cfg ;
    assign mackerel_mp.overs_cfg      = mackerel_sp.overs_cfg ;
    assign mackerel_mp.dither_cfg     = mackerel_sp.dither_cfg ;
    assign mackerel_mp.epcal          = mackerel_sp.epcal ;
    assign mackerel_mp.dscal          = mackerel_sp.dscal ;
    assign mackerel_mp.stc_cal        = mackerel_sp.stc_cal ;
    assign mackerel_mp.lv_gain        = mackerel_sp.lv_gain ;
    assign mackerel_mp.comp_en        = mackerel_sp.comp_en ;
    assign mackerel_mp.comp_val       = mackerel_sp.comp_val ;
    assign mackerel_mp.tst_dig_in     = mackerel_sp.tst_dig_in ;
    assign mackerel_mp.mod_lowsup     = mackerel_sp.mod_lowsup ;
    assign mackerel_sp.mod_ready   = mackerel_mp.mod_ready ;
    assign mackerel_sp.busy        = mackerel_mp.busy ;
    assign mackerel_sp.result      = mackerel_mp.result ;
    assign mackerel_sp.eoc         = mackerel_mp.eoc ;
    assign mackerel_sp.eoc_pre     = mackerel_mp.eoc_pre ;
    assign mackerel_sp.tst_dig_out = mackerel_mp.tst_dig_out ;

// ---------------------------------------------------------------------------

endmodule


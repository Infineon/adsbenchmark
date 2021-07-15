`timescale 1ns/1ns

//`uselib lib=ipdb_common_cell_lib

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

module saradc_11b_dig_core
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
     input               clk,
     input               nres,
     // Interfaces
     saradc_11b_dig_adif_if.mp          adif,
     saradc_11b_dig_mackerel_if.fsm     mackerel_fsm,
     saradc_11b_dig_mackerel_if.startup mackerel_startup

     );

    import saradc_11b_pkg::*;

    // startup -------------------------------------------------------------------
    logic su_ocs_high;

    logic cp_clk_ldo_enable;
    logic enable_conv;
    logic enable_fsms;
    logic scab_clk_enable_startup;
    logic sucal;
    logic sucal_done;

    saradc_11b_dig_startup startup_inst(
                                         .clk                 (clk                     ),
                                         .nres                (nres                    ),
                                         .mackerel            (mackerel_startup        ),
                                         .sucal_done_i        (sucal_done              ),
                                         .cp_clk_ldo_enable_o (cp_clk_ldo_enable       ),
                                         .enable_conv_o       (enable_conv             ),
                                         .enable_fsms_o       (enable_fsms             ),
                                         .enable_o            (adif.enable             ),
                                         .lowsup_o            (adif.lowsup             ),
                                         .release_ldo_o       (adif.release_ldo        ),
                                         .scab_clk_enable_o   (scab_clk_enable_startup ),
                                         .su_ocs_high_o       (su_ocs_high             ),
                                         .sucal_o             (sucal                   )
                                         );

    // fsm -----------------------------------------------------------------------

    logic sar_clk_enable;
    logic scab_clk_enable_fsm;

    saradc_11b_dig_fsm # (.N_CHANNELS (N_CHANNELS ),
                           .N_CONV_BITS  (N_CONV_BITS  ),
                           .N_TRACK_BITS (N_TRACK_BITS ),
                           .N_OVERS_BITS (N_OVERS_BITS ),
                           .SAR_MSB      (SAR_MSB      ),
                           .CAL_MSB      (CAL_MSB      ),
                           .TRACK_MSB    (TRACK_MSB    )
                           )
    fsm_inst(
             .clk                    (clk                  ),
             .nres                   (nres                 ),
             .mackerel               (mackerel_fsm         ),
             .comp_i                 (adif.comp            ),
             .enable_conv_i          (enable_conv          ),
             .enable_fsms_i          (enable_fsms          ),
             .sar_i                  (adif.sar             ),
             .su_ocs_high_i          (su_ocs_high          ),
             .sucal_i                (sucal                ),
             .track_i                (adif.track           ),
             .cal_o                  (adif.cal             ),
             .comp_res_o             (adif.comp_res        ),
             .din_n_o                (adif.din_n           ),
             .en_vain_lv_o           (adif.en_vain_lv      ),
             .ocs_o                  (adif.ocs             ),
             .ref_o                  (adif.refe            ),
             .sample_ch_o            (adif.sample_ch       ),
             .sar_clk_enable_o       (sar_clk_enable       ),
             .sar_res_o              (adif.sar_res         ),
             .scab_clk_enable_o      (scab_clk_enable_fsm  ),
             .sesp_del_o             (adif.sesp_del        ),
             .set_sar_o              (adif.set_sar         ),
             .set_track_o            (adif.set_track       ),
             .sucal_done_o           (sucal_done           ),
             .track_res_o            (adif.track_res       ),
             .trackin_n_o            (adif.trackin_n       )
             );



    // bill & mux ----------------------------------------------------------------

    ipdb_common_clk_gate ipdb_common_clk_gate_sar_clk_inst(
                                                           .clk_i  (clk           ),
                                                           .en_i   (sar_clk_enable),
                                                           .scen_i (1'b0          ),
                                                           .clk_o  (adif.sar_clk  )
                                                           );

    ipdb_common_clk_gate ipdb_common_clk_gate_scab_clk_inst(
                                                            .clk_i  (clk                                          ),
                                                            .en_i   (scab_clk_enable_startup & scab_clk_enable_fsm),
                                                            .scen_i (1'b0                                         ),
                                                            .clk_o  (adif.scab_clk                                )
                                                            );

    ipdb_common_clk_gate ipdb_common_clk_gate_cp_clk_ldo_inst(
                                                              .clk_i  (clk              ),
                                                              .en_i   (cp_clk_ldo_enable),
                                                              .scen_i (1'b0             ),
                                                              .clk_o  (adif.cp_clk_ldo  )
                                                              );


// ---------------------------------------------------------------------------

endmodule


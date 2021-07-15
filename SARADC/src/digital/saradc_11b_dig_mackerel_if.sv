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

/**
 * this interface connects the signals from dig_top to lower hierarchy
 * dig_core, dig_fsm, dig_startup, etc
 * The following modports are implemented (necessary for clean linting):
 * - mp
 * - sp
 * - fsm
 * - startup
 * - core
 */
interface saradc_11b_dig_mackerel_if
    #
    (CHNR_MSB         = 4,
     SAR_MSB          = 12,
     RESULT_MSB       = 10,
     TST_DIG_IN_SIZE  = 24,
     TST_DIG_OUT_SIZE = 19
     )
    (
     input clk_i,
     input res_n_i
     );

    logic                      busy;
    logic [CHNR_MSB:0]         chnr;
    logic                      comp_en;
    logic [SAR_MSB:0]          comp_val;
    logic [1:0]                dither_cfg;
    logic                      dscal;
    logic                      eoc;
    logic                      eoc_pre;
    logic                      epcal;
    logic                      lv_gain;
    logic                      mod_enable;
    logic                      mod_lowsup;
    logic                      mod_ready;
    logic [1:0]                overs_cfg;
    logic [RESULT_MSB:0]       result;
    logic                      sesp;
    logic                      start_adc;
    logic [1:0]                stc;
    logic [1:0]                stc_cal;
    logic [1:0]                track_cfg;
    logic [TST_DIG_IN_SIZE:0]  tst_dig_in;
    logic [TST_DIG_OUT_SIZE:0] tst_dig_out;


    // tst_dig renaming (sp only) ------------------------------------------------
    //TODO: realign and review test bits
    logic       tst_dig_msb_sel ;
    logic       tst_dig_msb_en4conv ;
    logic       tst_dig_msb_en4fcomp ;
    logic       tst_dig_msb_en4pcal ;
    logic [1:0] tst_dig_msb_scal_cfg ;
    logic       tst_dig_sesp_ana_del_off ;
    logic       tst_dig_sesp_dig_spread_short ;
    logic [2:0] tst_dig_sel ;
    logic [5:0] tst_dig_cal_val ;
    logic       tst_dig_cal_write ;
    logic [1:0] tst_dig_cal_filter_cfg ;

    always_comb
    begin
        tst_dig_msb_sel               = tst_dig_in[0] ;
        tst_dig_msb_en4conv           = tst_dig_in[1] ;
        tst_dig_msb_en4fcomp          = tst_dig_in[2] ;
        tst_dig_msb_en4pcal           = tst_dig_in[3] ;
        tst_dig_msb_scal_cfg          = tst_dig_in[6:5] ;
        tst_dig_sesp_ana_del_off      = tst_dig_in[7] ;
        tst_dig_sesp_dig_spread_short = tst_dig_in[8] ;
        tst_dig_sel                   = tst_dig_in[11:9] ;
        tst_dig_cal_val               = tst_dig_in[17:12] ;
        tst_dig_cal_write             = tst_dig_in[18] ;
        tst_dig_cal_filter_cfg        = tst_dig_in[20:19] ;
    end

    // ---------------------------------------------------------------------------

    // used between
    modport mp(
               input busy,
               input eoc,
               input eoc_pre,
               input mod_ready,
               input result,
               input tst_dig_out,
               output chnr,
               output comp_en,
               output comp_val,
               output dither_cfg,
               output dscal,
               output epcal,
               output lv_gain,
               output mod_enable,
               output mod_lowsup,
               output overs_cfg,
               output sesp,
               output start_adc,
               output stc,
               output stc_cal,
               output track_cfg,
               output tst_dig_in
               );

    modport sp(
               input chnr,
               input comp_en,
               input comp_val,
               input dither_cfg,
               input dscal,
               input epcal,
               input lv_gain,
               input mod_enable,
               input mod_lowsup,
               input overs_cfg,
               input sesp,
               input start_adc,
               input stc,
               input stc_cal,
               input track_cfg,
               input tst_dig_in,
               output busy,
               output eoc,
               output eoc_pre,
               output mod_ready,
               output result,
               output tst_dig_out,
               // sp only signals
               input tst_dig_msb_sel ,
               input tst_dig_msb_en4conv ,
               input tst_dig_msb_en4fcomp ,
               input tst_dig_msb_en4pcal ,
               input tst_dig_msb_scal_cfg ,
               input tst_dig_sesp_ana_del_off ,
               input tst_dig_sesp_dig_spread_short ,
               input tst_dig_sel ,
               input tst_dig_cal_val ,
               input tst_dig_cal_write ,
               input tst_dig_cal_filter_cfg
               );

    /**
     * used in ...dig_startup.sv
     */
    modport startup(
                    input dscal,
                    input mod_enable,
                    input mod_lowsup,
                    output mod_ready
                    );

    /**
     * used in ...dig_fsm.sv
     */
    modport fsm(
                input chnr,
                input comp_en,
                input comp_val,
                input dither_cfg,
                input epcal,
                input lv_gain,
                input overs_cfg,
                input sesp,
                input start_adc,
                input stc,
                input stc_cal,
                input track_cfg,
                output busy,
                output eoc,
                output eoc_pre,
                output result,
                output tst_dig_out,
                // tst_dig_i mapped signals
                input tst_dig_msb_sel ,
                input tst_dig_msb_en4conv ,
                input tst_dig_msb_en4fcomp ,
                input tst_dig_msb_en4pcal ,
                input tst_dig_msb_scal_cfg ,
                input tst_dig_sesp_ana_del_off ,
                input tst_dig_sesp_dig_spread_short ,
                input tst_dig_sel ,
                input tst_dig_cal_val ,
                input tst_dig_cal_write ,
                input tst_dig_cal_filter_cfg
                );

endinterface


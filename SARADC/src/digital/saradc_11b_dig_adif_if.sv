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

// sorry for the pleonasm in the name, but "ad" is hard to search for in this project
interface saradc_11b_dig_adif_if
    # (N_CHANNELS = 16,
       N_SUPPL_CH = 8,
       SAR_MSB    = 12,
       CAL_MSB    = 5,
       TRACK_MSB  = 4)
    (
     input clk_i,
     input res_n_i
     );

    logic [N_CHANNELS-1:0] sample_ch;
    logic [2:0]            sesp_del;
    logic                  refe;     // "ref" is a keyword

    logic sar_res;
    logic track_res;
    logic comp_res;
    logic sar_clk;

    logic                 set_sar;
    logic [SAR_MSB+1:0]   din_n;
    logic                 set_track;
    logic [TRACK_MSB+1:0] trackin_n;
    logic [CAL_MSB:0]     cal;

    logic ocs;

    logic enable;
    logic release_ldo;
    logic en_vain_lv;
    logic scab_clk;
    logic cp_clk_ldo;

    logic [SAR_MSB:0]   sar;
    logic               comp;
    logic [TRACK_MSB:0] track;
    logic               lowsup;

    modport mp(
               output sample_ch,
               output sesp_del,
               output refe,

               output sar_res,
               output track_res,
               output comp_res,
               output sar_clk,

               output set_sar,
               output din_n,
               output set_track,
               output trackin_n,
               output cal,

               output ocs,

               output enable,
               output release_ldo,
               output en_vain_lv,
               output scab_clk,
               output cp_clk_ldo,

               input sar,
               input comp,
               input track,
               output lowsup
               );

    modport sp(
               input sample_ch,
               input sesp_del,
               input refe,

               input sar_res,
               input track_res,
               input comp_res,
               input sar_clk,

               input set_sar,
               input din_n,
               input set_track,
               input trackin_n,
               input cal,

               input ocs,

               input enable,
               input release_ldo,
               input en_vain_lv,
               input scab_clk,
               input cp_clk_ldo,

               output sar,
               output comp,
               output track,
               input lowsup
               );

endinterface


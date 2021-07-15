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

package saradc_11b_pkg;
    /***************************************************************************
     ********************* INTERFACE *******************************************
     ***************************************************************************
     */

    localparam int N_CHANNELS       = 14; //32;
    localparam int N_CONV_BITS      = 11;
    localparam int N_TRACK_BITS     = 1;
    localparam int N_OVERS_BITS     = 1;
    localparam int CHNR_MSB         = 4; // CHNR_MSB=log2(N_CHANNELS)
    localparam int CAL_MSB          = 5;
    localparam int TRACK_MSB        = 4;
    localparam int SAR_MSB          = N_CONV_BITS+2-1; // depends on redundancy of SAR array
    localparam int RESULT_MSB       = N_CONV_BITS+N_OVERS_BITS-1;
    localparam int TST_DIG_IN_SIZE  = 36; // 1 less than in spec
    localparam int TST_DIG_OUT_SIZE = 19; // 1 less than in spec
    localparam int LOOPBACK_EN      = 1;  // enabling or disabling of Loopback test in saradc_11b_dig_scanmux.sv
    /***************************************************************************
     ********************* INTERFACE *******************************************
     ***************************************************************************
     */


    // =============================================================================
    // ============================ PRODUCT CONFIG (PC) ============================
    // =============================================================================

    // ---------- internal parameter -----------------------------------------------
    localparam FSM_COUNT_MSB                 = 8;
    localparam [FSM_COUNT_MSB-1:0] PC_ST_MIN = 8'd01;

    // ---------- standard channels ----------------------------------------------

    localparam [31:0] PC_LV_CHANNELS    = 32'b0000_0000_0000_0000_0011_1110_0000_0000;
    localparam [31:0] PC_INVAL_CHANNELS = 32'b1111_1111_1111_1111_1100_0000_0000_0000;
    // special type of LV channels: supplementary (internal) channels
    localparam [31:0] PC_SUPPL_CHANNELS = 32'b0000_0000_0000_0000_0011_0000_0000_0000;



    // [no of cycles], must be greater or equal to 1
    localparam [FSM_COUNT_MSB-1:0] PC_DEFAULT_ST [31:0] = '{
                                                            // non-existent channels have smallest possible sample time
                                                            // --------------
                                                            PC_ST_MIN, // 31
                                                            PC_ST_MIN, // 30
                                                            PC_ST_MIN, // 29
                                                            PC_ST_MIN, // 28
                                                            // --------------
                                                            PC_ST_MIN, // 27
                                                            PC_ST_MIN, // 26
                                                            PC_ST_MIN, // 25
                                                            PC_ST_MIN, // 24
                                                            // --------------
                                                            PC_ST_MIN, // 23
                                                            PC_ST_MIN, // 22
                                                            PC_ST_MIN, // 21
                                                            PC_ST_MIN, // 20
                                                            // --------------
                                                            PC_ST_MIN, // 19
                                                            PC_ST_MIN, // 18
                                                            PC_ST_MIN, // 17
                                                            PC_ST_MIN, // 16
                                                            // --------------
                                                            PC_ST_MIN, // 15
                                                            PC_ST_MIN, // 14
                                                            // LV channels
                                                            8'd8,     // 13
                                                            8'd8,     // 12
                                                            8'd8,     // 11
                                                            8'd8,     // 10
                                                            8'd8,     // 9
                                                            // non-existent channels have smallest possible sample time
                                                            PC_ST_MIN, // 8
                                                            // --------------
                                                            PC_ST_MIN, // 7
                                                            PC_ST_MIN, // 6
                                                            PC_ST_MIN, // 5
                                                            PC_ST_MIN, // 4
                                                            // --------------
                                                            PC_ST_MIN, // 3
                                                            PC_ST_MIN, // 2
                                                            PC_ST_MIN, // 1
                                                            PC_ST_MIN  // 0
                                                            };

    // ---------------------------------------------------------------------------

    // ---------- startup --------------------------------------------------------

    `ifndef NB

        localparam [6:0] PC_ENABLE_DEL  = 7'd63; // 0 = 1 cycle
        localparam [6:0] PC_REL_LDO_DEL = 7'd30; // -||-
        localparam [6:0] PC_OCS_DEL     = 7'd3;  // -||-
        localparam [6:0] PC_SUCAL_DEL   = 7'd19; // -||-

    `else

        localparam [6:0] PC_ENABLE_DEL  = 7'd0; // NB variant - all times minimum
        localparam [6:0] PC_REL_LDO_DEL = 7'd0; // NB variant - all times minimum
        localparam [6:0] PC_OCS_DEL     = 7'd0; // NB variant - all times minimum
        localparam [6:0] PC_SUCAL_DEL   = 7'd0; // NB variant - all times minimum

    `endif

    // ---------- other config ---------------------------------------------------

    localparam PC_MSB_EN4CONV        = 0;
    localparam PC_MSB_EN4FCOMP       = 1;
    localparam PC_MSB_EN4PCAL        = 1;
    localparam [1:0] PC_MSB_SCAL_CFG = 1; // 0 = 1 cycle, 1 = 2 cycles, 2 = 4 cycles, 3 = 8 cycles


    // ---------- calibration ----------------------------------------------------

    // [no of cycles], must be greater or equal to 1
    // doubled for sucal
    localparam [5:0] PC_STC_CAL [3:0] = '{
                                          6'd16, // 3
                                          6'd08, // 2
                                          6'd04, // 1
                                          6'd02  // 0
                                          };

    // ---------- Technology option ----------------------------------------------

    localparam logic PC_SPT9_SPT10N = 1'b0; // SPT9 = 1; SPT10 = 0;

    // ---------------------------------------------------------------------------


    /***************************************************************************
     ********************* CAP ARRAY VALUES ************************************
     ***************************************************************************
     */

    localparam CAP_MSB                    = 12;
    localparam [10:0] cap_val [CAP_MSB:0] = '{
                                              11'd824 , // cap 12
                                              11'd496 , // cap 11
                                              11'd296 , // cap 10
                                              11'd176 , // cap 9
                                              11'd108 , // cap 8
                                              11'd64 ,  // cap 7
                                              11'd36 ,  // cap 6
                                              11'd22 ,  // cap 5
                                              11'd12 ,  // cap 4
                                              11'd7 ,   // cap 3
                                              11'd4 ,   // cap 2
                                              11'd2 ,   // cap 1
                                              11'd1     // cap 0
                                              };


    // LV channels gain values ---------------------------------------------------

    localparam [CAP_MSB:0] cv_lv_gain [1:0] = '{
                                                13'h1A44 , // gain 3/4
                                                13'h1FFF   // gain 1
                                                };

endpackage : saradc_11b_pkg

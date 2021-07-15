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

module saradc_11b_dig_startup
    import saradc_11b_pkg::*;
    (
     input               clk,
     input               nres,
     input               sucal_done_i,
     saradc_11b_dig_mackerel_if.startup mackerel,

     // ADIF
     output logic enable_o,
     output logic lowsup_o,
     output logic release_ldo_o,

     // other
     output logic cp_clk_ldo_enable_o,
     output logic enable_conv_o,
     output logic enable_fsms_o,
     output logic scab_clk_enable_o,
     output logic su_ocs_high_o,
     output logic sucal_o
     );

    //
    //`include "saradc_11b_pc.svh"
    // ---------------------------------------------------------------------------

    // localparams etc. ----------------------------------------------------------

    localparam NO_OF_REL_LDO_PULSES = 8;

    // startup fsm ---------------------------------------------------------------

    logic [7:0] counter; // max-value 127
    logic       lowsup;

    always_comb lowsup = mackerel.mod_lowsup & PC_SPT9_SPT10N; // lowsup option only for spt9

    enum {
          ST_IDLE,
          ST_ENABLE,
          ST_REL_LDO,
          ST_WAIT_OCS,
          ST_WAIT_SUCAL, // must be defined after ST_WAIT_READY (comparison used)
          ST_PRE_SUCAL,  // -||-
          ST_SUCAL,      // -||-
          ST_RUN         // -||-
          } state_t;

    task INIT;
        begin
            // mackerel
            mackerel.mod_ready  <= '0;
            // adif
            enable_o            <= '0;
            release_ldo_o       <= '0;
            lowsup_o            <= '0;
            // other
            su_ocs_high_o       <= '0;
            enable_fsms_o       <= '0;
            sucal_o             <= '0;
            enable_conv_o       <= '0;
            scab_clk_enable_o   <= '0;
            cp_clk_ldo_enable_o <= '0;
            // internal
            counter             <= '0;
            state_t               <= ST_IDLE;
        end
    endtask

    always_ff @(negedge nres or posedge clk)
    begin
        if (!nres)
        begin
            INIT;
        end
        else
        begin

            case (state_t)

                ST_IDLE :
                begin
                    if (mackerel.mod_enable)
                    begin
                        enable_o            <= 1'b1;
                        lowsup_o            <= lowsup;
                        cp_clk_ldo_enable_o <= lowsup;
                        scab_clk_enable_o   <= 1'b1;
                        counter             <= PC_ENABLE_DEL;
                        state_t             <= ST_ENABLE;
                    end
                end

                ST_ENABLE :
                begin
                    if (!counter)
                    begin
                        release_ldo_o      <= 1'b1;
                        counter            <= PC_REL_LDO_DEL;
                        state_t            <= ST_REL_LDO;
                    end
                    else
                    begin
                        counter <= counter - 1;
                    end
                end

                ST_REL_LDO :
                begin
                    if (!counter)
                    begin
                        su_ocs_high_o <= 1'b1;
                        counter       <= (NO_OF_REL_LDO_PULSES * 2 - 1);
                        state_t       <= ST_WAIT_OCS;
                    end
                    else
                    begin
                        counter <= counter - 1;
                    end
                end

                ST_WAIT_OCS :
                begin
                    if (!counter)
                    begin
                        su_ocs_high_o <= 1'b0;
                        counter       <= PC_SUCAL_DEL;
                        state_t       <= ST_WAIT_SUCAL;
                    end
                    else
                    begin
                        counter <= counter - 1;
                    end
                end

                ST_WAIT_SUCAL :
                begin
                    if (!counter)
                    begin
                        enable_fsms_o <= 1'b1;
                        state_t       <= ST_PRE_SUCAL;
                    end
                    else
                    begin
                        counter <= counter - 1;
                    end
                end

                ST_PRE_SUCAL :
                begin
                    sucal_o <= !mackerel.dscal;
                    state_t <= ST_SUCAL;
                end

                ST_SUCAL :
                begin
                    sucal_o <= 1'b0;
                    if (sucal_done_i | mackerel.dscal)
                    begin
                        mackerel.mod_ready <= 1'b1;
                        enable_conv_o      <= 1'b1;
                        state_t            <= ST_RUN;
                    end
                end

                ST_RUN :
                begin
                end

            endcase

            ///// priority transitions /////

            if (!mackerel.mod_enable && (ST_IDLE != state_t))
            begin
                INIT;
            end

        end
    end

// ---------------------------------------------------------------------------

endmodule


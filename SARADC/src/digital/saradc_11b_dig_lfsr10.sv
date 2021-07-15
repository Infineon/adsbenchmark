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

module saradc_11b_dig_lfsr10
    (
     input        clk,
     input        nres,
     input        enable_i,
     output [9:0] val_o
     );

    logic [9:0] lfsr10;

    // x^10 + x^7 + 1 --> period length = 1023

    always_ff @(negedge nres or posedge clk)
    begin
        if (!nres)
        begin
            lfsr10 <= '1;
        end
        else
        begin
            if (enable_i)
            begin
                lfsr10[9:1]  <= lfsr10[8:0];
                lfsr10[0]    <= lfsr10[9] ^ lfsr10[6];
            end
        end
    end

    assign val_o = lfsr10;

endmodule


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

module ipdb_common_sync_rst
  (
     input  logic clk_i          , // destination clock
     input  logic reset_n_i      , // asynch. reset
     input  logic scan_mode_i    , // scan mode signal
     output logic synch_reset_o    // synchronous reset output
  );

  logic synch_data_s;
  logic one_s;
  
  assign one_s = 1'b1 ;
 

//-----------------------------------------------------------------------------------------
// Instantiation ipdb_common_sync
// output: synch_data_s
//----------------------------------------------------------------------------------------- 
  ipdb_common_sync 
  u_synchronizer(
    .clk_i     (clk_i),
    .reset_n_i (reset_n_i),
    .data_i    (one_s),
    .data_o    (synch_data_s)
  );


//-----------------------------------------------------------------------------------------
// Output Multiplexer
// output: synch_reset_o
//----------------------------------------------------------------------------------------- 
  always_comb 
  begin:synch_reset_mux_p
    case (scan_mode_i)//synopsys infer_mux
      1'b0    : synch_reset_o = synch_data_s;
      1'b1    : synch_reset_o = reset_n_i;      
      default : synch_reset_o = scan_mode_i & 1'b1;		// x and z handling
    endcase
  end

endmodule

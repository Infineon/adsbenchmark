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

module ipdb_common_sync
  // pragma synthesis_off 
  // pragma coverage off 
  `ifndef SYNTHESIS
  # (
    parameter logic   SIM_JITTER  = 0,    // simulate with synchronizer capture jitter (1) or not (0)
    parameter integer WINDOW	  = 0,    // sim_jitter window in ns (0: jitter always)
    parameter time    WINDOW_T    = 0fs   // time can be fs,ps,ns,us,ms,s
  )   
  `endif
  // pragma synthesis_on 
  // pragma coverage on 
  (
    input  logic clk_i     , // destination clock
    input  logic reset_n_i , // asynch. reset
    input  logic data_i    , // data in
    output logic data_o      // data out
  );
  
  logic    firststage_synchronizer_s;
  logic    secondstage_ff_s;

  always @(
    posedge clk_i or negedge reset_n_i
  )
  begin
    if(!reset_n_i)
      firststage_synchronizer_s <= 0;
    else begin
      firststage_synchronizer_s <= data_i & 1'b1;	// x and z handling
    end         
  end  



//-----------------------------------------------------------------------------------------
// Second Synchronizer Flip-Flop stage
// output: secondstage_ff_s
//-----------------------------------------------------------------------------------------
  always @(posedge clk_i or negedge reset_n_i)
  begin
    if(!reset_n_i)
      secondstage_ff_s <= 0;
    else
      secondstage_ff_s <= firststage_synchronizer_s;       
  end  



//-----------------------------------------------------------------------------------------
// Synchronizer output
// output: data_o
//-----------------------------------------------------------------------------------------
  assign data_o = secondstage_ff_s;

endmodule

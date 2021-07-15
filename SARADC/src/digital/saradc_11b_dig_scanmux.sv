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

module saradc_11b_dig_scanmux
  #
  (
    N_CHANNELS   = 16,
    SAR_MSB      = 12,
    CAL_MSB      = 5,
    TRACK_MSB    = 4,
    LOOPBACK_EN  = 1
  )
  (

    input        scan_mode_i,
    saradc_11b_dig_adif_if.sp   adif_test,
    saradc_11b_dig_adif_if.mp   adif_sm
  );
  // core --> analog -----------------------------------------------------------

  always_comb
  begin
    adif_sm.sample_ch            = adif_test.sample_ch            ;
    adif_sm.sesp_del             = adif_test.sesp_del             ;
    adif_sm.en_vain_lv           = adif_test.en_vain_lv           ;
    adif_sm.refe                 = adif_test.refe                 ;
    adif_sm.sar_res              = adif_test.sar_res              ;
    adif_sm.track_res            = adif_test.track_res            ;
    adif_sm.comp_res             = adif_test.comp_res             ;
    adif_sm.sar_clk              = adif_test.sar_clk              ;  // no loopback ! (clock)
    adif_sm.set_sar              = adif_test.set_sar              ;
    adif_sm.din_n                = adif_test.din_n                ;
    adif_sm.set_track            = adif_test.set_track            ;
    adif_sm.trackin_n            = adif_test.trackin_n            ;
    adif_sm.cal                  = adif_test.cal                  ;
    adif_sm.ocs                  = adif_test.ocs                  ;
    adif_sm.enable               = adif_test.enable               ;
    adif_sm.release_ldo          = adif_test.release_ldo          ;
    adif_sm.scab_clk             = adif_test.scab_clk             ;  // no loopback ! (clock)
    adif_sm.cp_clk_ldo           = adif_test.cp_clk_ldo           ;  // no loopback ! (clock)
    adif_sm.lowsup               = adif_test.lowsup               ;
  end

  // analog --> core -----------------------------------------------------------

  localparam integer                        LOOPBACK_SIZE      =
   N_CHANNELS  + //$bits(adif_test.sample_ch  )
   3           + //$bits(adif_test.sesp_del   )
   1           + //$bits(adif_test.en_vain_lv )
   1           + //$bits(adif_test.refe       )
   1           + //$bits(adif_test.sar_res    )
   1           + //$bits(adif_test.track_res  )
   1           + //$bits(adif_test.comp_res   )
   1           + //$bits(adif_test.set_sar    )
   SAR_MSB+2   + //$bits(adif_test.din_n      )
   1           + //$bits(adif_test.set_track  )
   TRACK_MSB+2 + //$bits(adif_test.trackin_n  )
   CAL_MSB+1   + //$bits(adif_test.cal        )
   1           + //$bits(adif_test.ocs        )
   1           + //$bits(adif_test.enable     )
   1           + //$bits(adif_test.release_ldo)
   1           ; //$bits(adif_test.lowsup     )


  localparam integer                        LOOPBACK_FOLD_SIZE = (SAR_MSB+1)+1+(TRACK_MSB+1)-1;
  localparam integer                        iterations         = (LOOPBACK_SIZE +1) / (LOOPBACK_FOLD_SIZE+1);
  localparam integer                        rest               = (LOOPBACK_SIZE +1) % (LOOPBACK_FOLD_SIZE+1);
  logic              [LOOPBACK_SIZE:0]      loopback_v;
  logic              [LOOPBACK_FOLD_SIZE:0] loopback_fold_v;                                                                                     // size of sm.sar + sm.comp + sm.track

  always_comb
  begin
    adif_test.sar         = adif_sm.sar         ;
    adif_test.comp        = adif_sm.comp        ;
    adif_test.track       = adif_sm.track       ;
  end

  // loopback ------------------------------------------------------------------

  always_comb loopback_v = {
      adif_test.sample_ch            ,
      adif_test.sesp_del             ,
      adif_test.en_vain_lv           ,
      adif_test.refe                 ,
      adif_test.sar_res              ,
      adif_test.track_res            ,
      adif_test.comp_res             ,
      adif_test.set_sar              ,
      adif_test.din_n                ,
      adif_test.set_track            ,
      adif_test.trackin_n            ,
      adif_test.cal                  ,
      adif_test.ocs                  ,
      adif_test.enable               ,
      adif_test.release_ldo          ,
      adif_test.lowsup
    };

  // dynamic calculation of loopback_fold
  always_comb
  begin
    loopback_fold_v = loopback_v[LOOPBACK_FOLD_SIZE : 0];
    for (integer k = 1; k < iterations; k++)
    begin
      loopback_fold_v ^= loopback_v[(LOOPBACK_FOLD_SIZE)*(k)+k +: LOOPBACK_FOLD_SIZE+1]; // [starting index +: width (will be added to starting index)]
    end
    loopback_fold_v ^= loopback_v[LOOPBACK_SIZE:LOOPBACK_SIZE-rest+1];
  end



endmodule


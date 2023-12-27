//*******************************************************************************************
//**
//**  File Name          : filter_3x3_mask.sv (SystemVerilog)
//**  Module Name        : filter_3x3_mask
//**                     :
//**  Module Description : Low Pass 3x3 calculation window for the parent module. 
//**                     : This module is a 2D smoothing (Low pass) filter that takes in
//**                     : a raster stream of data and outputs a filtered stream of data.
//**                     : Edge cases on the image are taken care of with the bypass signals
//**                     :
//**  Author             : Shen
//**                     :
//**  Creation Date      : 6/11/2015
//**                     : 
//**  Version History    :
//**                     :
//**
//*******************************************************************************************


// The Filter convolution Window:  
// -------------------------------------------
// _____________________________________
// |           |           |           |
// |   pix a   |   pix b   |   pix c   | 
// |   (x1)    |   (x2)    |   (x1)    |
// |___________|___________|___________|
// |           |           |           |
// |   pix d   |   pix e   |   pix f   |
// |   (x2)    |   (x4)    |   (x2)    |  
// |___________|___________|___________|
// |           |           |           |
// |   pix g   |   pix h   |   pix i   |  
// |   (x1)    |   (x2)    |   (x1)    |
// |___________|___________|___________|
 
// Bypass Select Note:
// bit 0: bypass top of window
// bit 1: bypass bottom of window
// bit 2: bypass left of window
// bit 3: bypass right of window 
 
module filter_3x3_mask
      #( parameter                 DWIDTH = 16 )
       ( input  logic              clk
       
       , input  logic        [3:0] bypass // bypass select (see note) 
     
       , input  logic [DWIDTH-1:0] data_a
       , input  logic [DWIDTH-1:0] data_b
       , input  logic [DWIDTH-1:0] data_c
       , input  logic [DWIDTH-1:0] data_d
       , input  logic [DWIDTH-1:0] data_e
       , input  logic [DWIDTH-1:0] data_f
       , input  logic [DWIDTH-1:0] data_g
       , input  logic [DWIDTH-1:0] data_h
       , input  logic [DWIDTH-1:0] data_i
       
       , output logic [DWIDTH-1:0] data_out
       );

logic [DWIDTH-1:0] pix_a ; 
logic [DWIDTH-1:0] pix_b ;
logic [DWIDTH-1:0] pix_c ;
logic [DWIDTH-1:0] pix_d ; 
logic [DWIDTH-1:0] pix_e ;
logic [DWIDTH-1:0] pix_f ;
logic [DWIDTH-1:0] pix_g ;
logic [DWIDTH-1:0] pix_h ;
logic [DWIDTH-1:0] pix_i ;

always_comb begin
  pix_a = bypass[0] | bypass[2] ? data_e : data_a ;
  pix_b = bypass[0]             ? data_e : data_b ;
  pix_c = bypass[0] | bypass[3] ? data_e : data_c ;
  pix_d = bypass[2]             ? data_e : data_d ;
  pix_e =                                  data_e ; // Always the center pixel 
  pix_f = bypass[3]             ? data_e : data_f ;
  pix_g = bypass[1] | bypass[2] ? data_e : data_g ;
  pix_h = bypass[1]             ? data_e : data_h ;
  pix_i = bypass[1] | bypass[3] ? data_e : data_i ;
end


logic [DWIDTH+1:0] sum_a   ; // grows 2 bits
logic [DWIDTH+2:0] sum_b   ; // grows 3 bits
logic [DWIDTH+1:0] sum_c   ; // grows 2 bits
logic [DWIDTH+3:0] sum_all ; // grows 4 bits



always_ff @ (posedge clk) begin                                           
  sum_a    <=   pix_a       + (pix_b << 1) +  pix_c       ;    // 1a  +  2b   +  1c    1st pipe
  sum_b    <=  (pix_d << 1) + (pix_e << 2) + (pix_f << 1) ;    // 2d  +  4e   +  2f
  sum_c    <=   pix_g       + (pix_h << 1) +  pix_i       ;    // 1g  +  2h   +  1i

  sum_all  <= sum_a + sum_b + sum_c ;  // Sum all              2nd pipe
  data_out <= sum_all >> 4          ;  // Divide by 16         3rd pipe 
end

endmodule



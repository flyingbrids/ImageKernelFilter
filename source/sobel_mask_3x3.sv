//**
//**  File Name          : sobel_mask_3x3.sv (SystemVerilog)
//**  Module Name        : sobel_mask_3x3
//**                     :
//**  Module Description : Sobel edge detect 3x3 convolution window for the parent module. 
//**                     : This module takes in a raster stream of data and outputs the
//**                     : sobel filtered stream of data.
//**                     : Edge cases on the image are taken care of with the bypass signals.
//**                     : This convolution window is for the VERTICAL sobel edge detect.
//**                     : Horizontal cases will be handled by the parent module by transposing 
//**                     : input data matrix
//**  Author             : Leon Shen
//**                     :
//**  Creation Date      : 10/7/2015
//**                     : 
//**  Version History    :
//**                     :
//**
//*******************************************************************************************
// The Filter convolution Window:  (sobel window)
// -------------------------------------------
//  ___________________________________
// |           |           |           |
// |   pix a   |   pix b   |   pix c   | 
// |   (x1)    |   (x2)    |   (x1)    |
// |___________|___________|___________|
// |           |           |           |
// |   pix d   |   pix e   |   pix f   |
// |   (x0)    |   (x0)    |   (x0)    |  
// |___________|___________|___________|
// |           |           |           |
// |   pix g   |   pix h   |   pix i   |  
// |  -(x1)    |  -(x2)    |  -(x1)    |
// |___________|___________|___________|
 
// Bypass Select Note:
// bit 0: bypass top of window
// bit 1: bypass bottom of window
// bit 2: bypass left of window
// bit 3: bypass right of window 
 
module sobel_mask_3x3
      #( parameter                 DWIDTH = 10 )
       ( input  logic              clk       
       , input  logic        [3:0] bypass // bypass select (see note) 
		 , input  logic              edge_sel     
       , input  logic [DWIDTH-1:0] data_a
       , input  logic [DWIDTH-1:0] data_b
       , input  logic [DWIDTH-1:0] data_c
       , input  logic [DWIDTH-1:0] data_d
       , input  logic [DWIDTH-1:0] data_e
       , input  logic [DWIDTH-1:0] data_f
       , input  logic [DWIDTH-1:0] data_g
       , input  logic [DWIDTH-1:0] data_h
       , input  logic [DWIDTH-1:0] data_i
       
       , output logic signed [DWIDTH+2:0] data_out
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
//  pix_d = bypass[2]             ? data_e : data_d ;
//  pix_e =                                  data_e ; // Always the center pixel 
//  pix_f = bypass[3]             ? data_e : data_f ;
  pix_g = bypass[1] | bypass[2] ? data_e : data_g ;
  pix_h = bypass[1]             ? data_e : data_h ;
  pix_i = bypass[1] | bypass[3] ? data_e : data_i ;
end

logic [DWIDTH+1:0] sum_a   ; // grows 2 bits 
                // sum_b   ; // This is zeros
logic [DWIDTH+1:0] sum_c   ; // grows 2 bits
logic signed [DWIDTH+2:0] sum_all ; // grows two bits + sign bit 



always_ff @ (posedge clk) begin                                           
  sum_a    <=  (pix_a ) + (pix_b << 1) + (pix_c ) ;    // 1a  +  2b   +  1c    1st pipe
//sum_b    <=    0      +     0        +   0
  sum_c    <=  (pix_g ) + (pix_h << 1) + (pix_i ) ;    // 1g  +  2h   +  1i    

  sum_all  <= edge_sel ? sum_c - sum_a : sum_a - sum_c   ;       // Sum all              2nd pipe
  data_out <= sum_all  ;            
end

endmodule



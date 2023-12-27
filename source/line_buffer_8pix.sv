//*******************************************************************************************
//**
//**  File Name          : line_buffer_8pix.sv
//**  Module Name        : line_buffer_8pix
//**                     :
//**  Module Description : This module can be used as row buffer for image processing 
//**                     : convolution kernel
//**                     : 
//**                     :
//**  Author             : Shen
//**                     :
//**  Creation Date      : 
//**                     : 
//**  Version History    :
//**                     :
//**
//*******************************************************************************************
module line_buffer_8pix 
#( 
	   parameter          DWIDTH = 10
    , parameter          PIXCNT = 8 
    , parameter          COLS   = 2448 // max col  
	 , parameter          DEPTH  = COLS/PIXCNT
)
(
     input logic [$clog2(DEPTH)-1:0] tap_N // # of taps 
    ,input logic [DWIDTH*PIXCNT-1:0] D
    ,input logic 							 clk
	 ,input logic                     rst
    ,input logic                     enable
    ,output logic [DWIDTH*PIXCNT-1:0]Q
);
logic rd_enable, empty;
logic [$clog2(DEPTH)-1:0] count;
assign rd_enable = ~empty & (count == tap_N) & enable;

sync_fifo
 #( .depth         ( DEPTH         ) 
  , .width         ( DWIDTH*PIXCNT )
  )
shift_register
  ( .clk           ( clk        )
  , .reset         ( rst        )
  , .wr_enable     ( enable     ) // I
  , .rd_enable     ( rd_enable  ) // I
  , .wr_data       ( D          ) // I
  , .rd_data       ( Q          ) // O
  , .empty         ( empty      )
  , .count         ( count      ) // O
  ) ; 
  
  endmodule 
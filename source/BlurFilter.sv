//*******************************************************************************************
//**
//**  File Name          : BlurFilter
//**  Module Name        : Top level 
//**                     :
//**  Module Description : 
//**                     : 
//**                     :
//**  Author             : Leon
//**                     :
//**  Creation Date      : 5/15/2020
//**                     : 
//**  Version History    : 
//**                     :          
//**
//*******************************************************************************************
module BlurFilter 
#(
	   parameter          DWIDTH = 10
    , parameter          PIXCNT = 8      // # of pixel processed in parallel 
    , parameter          ROWS   = 2048  // Max row
    , parameter          COLS   = 2448  // Max col
)
(	   
      input   logic                       sys_clk
    , input   logic                       sys_rst  // reset associated with clk
    , input   logic                       bypass_filt // disable filter 
    , input   logic    [$clog2(ROWS)-1:0] rowSize 
    , input   logic    [$clog2(COLS)-1:0] colSize
    , input   logic                       new_frame 
    , input   logic   [DWIDTH*PIXCNT-1:0] data_in    // virtual IO
    , input   logic                       data_vld   // virtual IO
    , output  logic   [DWIDTH*PIXCNT-1:0] data_out  // virtual IO
    , output  logic                       out_vld   // virtual IO
);

// register input 
logic                       bypass_filt_r;
logic    [$clog2(ROWS)-1:0] rowSize_r; 
logic    [$clog2(COLS)-1:0] colSize_r;
logic                       new_frame_r; 
logic   [DWIDTH*PIXCNT-1:0] data_in_r;    
logic                       data_vld_r;  
 
always @ (posedge sys_clk) begin 
   bypass_filt_r <= bypass_filt;
   rowSize_r <= rowSize; 
   colSize_r <= colSize;
   new_frame_r <= new_frame; 
   data_in_r <= data_in;    
   data_vld_r <= data_vld;  
end 

// Gaussian 3x3 Filter, direct implmentation  
logic [DWIDTH*PIXCNT-1:0] filt_3x3_data;
logic                     filt_3x3_vld;
 
filter_3x3 
 #( .DWIDTH          ( DWIDTH )
  , .PIXCNT          ( PIXCNT )
  , .ROWS            ( ROWS   )
  , .COLS            ( COLS   )
 )                  
filter_3x3_i 
  ( .clk             ( sys_clk           )
  , .rst             ( sys_rst           )
  , .bypass_filt     ( bypass_filt_r     ) 
  , .rows            ( rowSize_r         )
  , .cols            ( colSize_r         )
  , .new_frame       ( new_frame_r       )
  , .data_in         ( data_in_r         )
  , .data_vld        ( data_vld_r        )
  , .data_out        ( filt_3x3_data     )
  , .out_vld         ( filt_3x3_vld      )
  ) ; /* synthesis keep */


// Gaussian 5x5 Filter, direct implmentation  









endmodule 
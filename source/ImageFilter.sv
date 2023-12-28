//*******************************************************************************************
//**
//**  File Name          : ImageFilter
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
module ImageFilter 
#(
	   parameter          DWIDTH = 10
    , parameter          PIXCNT = 8      // # of pixel processed in parallel 
    , parameter          ROWS   = 2048  // Max row
    , parameter          COLS   = 2448  // Max col
	 , parameter          MAG_WIDTH = 13
    , parameter          DIR_WIDTH =  3
    , parameter          R_WIDTH = 16
)
(	   
      input   logic                       sys_clk
    , input   logic                       sys_rst  // reset associated with clk
    , input   logic    [2:0]              bypass_filt // disable filter 
	 , input   logic                       filer_5x5_sel
    , input   logic    [$clog2(ROWS)-1:0] rowSize 
    , input   logic    [$clog2(COLS)-1:0] colSize
    , input   logic                       new_frame 
    , input   logic   [DWIDTH*PIXCNT-1:0] data_in    
    , input   logic                       data_vld   
    , output  logic   [PIXCNT-1:0]        mask_out  
	 , output  logic                       out_vld
);

// register input 
logic    [2:0]              bypass_filt_r;
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
logic [DWIDTH*PIXCNT-1:0] filt_5x5_data;
logic                     filt_5x5_vld; 
logic [DWIDTH*PIXCNT-1:0] filt_data;
logic                     filt_vld; 

(*keep*) filter_3x3 
 #( .DWIDTH          ( DWIDTH )
  , .PIXCNT          ( PIXCNT )
  , .ROWS            ( ROWS   )
  , .COLS            ( COLS   )
 )                  
filter_3x3_i 
  ( .clk             ( sys_clk           )
  , .rst             ( sys_rst           )
  , .bypass_filt     ( bypass_filt_r[0]  ) 
  , .rows            ( rowSize_r         )
  , .cols            ( colSize_r         )
  , .new_frame       ( new_frame_r       )
  , .data_in         ( data_in_r         )
  , .data_vld        ( data_vld_r        )
  , .data_out        ( filt_3x3_data     )
  , .out_vld         ( filt_3x3_vld      )
  ) ; 


// Gaussian 5x5 Filter, direct implmentation  
(*keep*) filter_5x5 
 #( .DWIDTH          ( DWIDTH )
  , .PIXCNT          ( PIXCNT )
  , .ROWS            ( ROWS   )
  , .COLS            ( COLS   )
 )                  
filter_5x5_i 
  ( .clk             ( sys_clk           )
  , .rst             ( sys_rst           )
  , .bypass_filt     ( bypass_filt_r[0]  ) 
  , .rows            ( rowSize_r         )
  , .cols            ( colSize_r         )
  , .new_frame       ( new_frame_r       )
  , .data_in         ( data_in_r         )
  , .data_vld        ( data_vld_r        )
  , .data_out        ( filt_5x5_data     )
  , .out_vld         ( filt_5x5_vld      )
) ; 

assign filt_data = filer_5x5_sel? filt_5x5_data : filt_3x3_data;
assign filt_vld  = filer_5x5_sel? filt_5x5_vld  : filt_3x3_vld; 

// Sobel edge detector, direct implemntation 
logic [(DWIDTH+3)*PIXCNT-1:0] data_out_v;
logic [(DWIDTH+3)*PIXCNT-1:0] data_out_h;
logic sobel_vld;
(*keep*) sobel_3x3
 #( .DWIDTH          ( DWIDTH )
  , .PIXCNT          ( PIXCNT )
  , .ROWS            ( ROWS   )
  , .COLS            ( COLS   )
 )                  
sobel_3x3_i 
  ( .clk             ( sys_clk           )
  , .rst             ( sys_rst           )
  , .bypass_filt     ( bypass_filt_r[1]  ) 
  , .rows            ( rowSize_r         )
  , .cols            ( colSize_r         )
  , .new_frame       ( new_frame_r       )
  , .data_in         ( filt_data         )
  , .data_vld        ( filt_vld          )
  , .data_out_v      ( data_out_v        )
  , .data_out_h      ( data_out_h        )
  , .out_vld         ( sobel_vld         )
  ) ;

logic [16:0] sobel_vld_shift;
logic grad_vld;
assign grad_vld = sobel_vld_shift[16];
always @ (posedge sys_clk) 
    sobel_vld_shift <= {sobel_vld_shift[15:0], sobel_vld};
  

// gradient filter after sobel edge. This is non-linear filter. 
logic   [(DIR_WIDTH+MAG_WIDTH)*PIXCNT-1:0] grad_out;
logic   [PIXCNT-1:0]                       grad_mask;  
genvar j;
generate
for (j=0; j<PIXCNT; j=j+1) 

begin : gradiant_filter
(*keep*) gradiant	
 #( 
    .DWIDTH         ( DWIDTH    )
  , .MAG_WIDTH      ( MAG_WIDTH )
  , .DIR_WIDTH      ( DIR_WIDTH )
  , .R_WIDTH        ( R_WIDTH   )
  ) 
gradiant_inst // 17 pipes
  (
    .clk       ( sys_clk          )
  , .threshold ( 300              ) 
  , .mask_in   ( sobel_vld        )
  , .x         ( data_out_h [j*(DWIDTH+3) +: DWIDTH+3] )
  , .y         ( data_out_v [j*(DWIDTH+3) +: DWIDTH+3] )
  , .grad_out  ( grad_out   [j*((DIR_WIDTH+MAG_WIDTH)) +: (DIR_WIDTH+MAG_WIDTH)] )
  , .mask_out  ( grad_mask  [j] )
  ) ;
end 
endgenerate

// This is a non-linear kernel. It analyzes the gradient direction of the center pixel 
// only preverse it point where is the maximum magnitude along the gradient line. 
// The window size is selected to be 3x3 
non_max_suppression non_max_suppression_int
  ( .clk         ( sys_clk     )
  , .rst         ( sys_rst     )
  , .bypass_filt ( bypass_filt_r[2] )
  , .new_frame   ( new_frame_r )
  , .rows        ( rowSize_r   )
  , .cols        ( colSize_r   )
  , .grad_in     ( grad_out    )
  , .mask_in     ( grad_mask   )
  , .data_vld    ( grad_vld    )
  , .mask_out    ( mask_out    )
  , .out_vld     ( out_vld     )
  ) ;



endmodule 
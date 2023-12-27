//*******************************************************************************************
//**
//**  File Name          : filter_3x3.sv 
//**  Module Name        : filter_3x3
//**                     :
//**  Module Description : 3x3 Kernel 2D Filter
//**                     : This module is a 2D smoothing (Low pass) filter that takes in
//**                     : a raster stream of data and outputs a filtered stream of data.
//**                     :
//**  Author             : Shen
//**                     :
//**  Creation Date      : 
//**                     : 
//**  Version History    :
//**                     :
//**
//*******************************************************************************************
 module filter_3x3
   #( 
	   parameter          DWIDTH = 10
    , parameter          PIXCNT = 8 
    , parameter          ROWS   = 2049 // max row
    , parameter          COLS   = 2448 // max col   
	 , parameter          PIXCNTBITS  = $clog2(PIXCNT)
	 )
	 
    ( 
	   input   logic                       clk
    , input   logic                       rst
    , input   logic                       bypass_filt
    , input   logic    [$clog2(ROWS)-1:0] rows
    , input   logic    [$clog2(COLS)-1:0] cols
    , input   logic                       new_frame
    , input   logic   [DWIDTH*PIXCNT-1:0] data_in
    , input   logic                       data_vld
    , output  logic   [DWIDTH*PIXCNT-1:0] data_out
    , output  logic                       out_vld
    ) ;
	   

logic [DWIDTH*PIXCNT-1:0] filt_data_out ;
logic [DWIDTH*PIXCNT-1:0] buff1_str  ;
logic [DWIDTH*PIXCNT-1:0] buff2_str  ;
logic                     buff1_full ;
logic                     buff2_full ;

logic  [DWIDTH-1:0] stream_array_a_dly0 [0:PIXCNT-1] ;
logic  [DWIDTH-1:0] stream_array_b_dly0 [0:PIXCNT-1] ;
logic  [DWIDTH-1:0] stream_array_c_dly0 [0:PIXCNT-1] ;

logic  [DWIDTH-1:0] stream_array_a_dly1 [0:PIXCNT-1] ;
logic  [DWIDTH-1:0] stream_array_b_dly1 [0:PIXCNT-1] ;
logic  [DWIDTH-1:0] stream_array_c_dly1 [0:PIXCNT-1] ;

logic  [DWIDTH-1:0] stream_array_a_dly2 [0:PIXCNT-1] ;
logic  [DWIDTH-1:0] stream_array_b_dly2 [0:PIXCNT-1] ;
logic  [DWIDTH-1:0] stream_array_c_dly2 [0:PIXCNT-1] ;

logic  stream_vld, reset;
assign reset = new_frame | rst;

always_ff @ (posedge clk or posedge reset) begin
  if (reset) begin
    stream_array_a_dly0 <= '{default:0};
    stream_array_b_dly0 <= '{default:0};
    stream_array_c_dly0 <= '{default:0};
    stream_array_a_dly1 <= '{default:0};
    stream_array_b_dly1 <= '{default:0};
    stream_array_c_dly1 <= '{default:0};
    stream_array_a_dly2 <= '{default:0};
    stream_array_b_dly2 <= '{default:0};
    stream_array_c_dly2 <= '{default:0};
  end else begin
    
    for (int n=0; n<PIXCNT; n++) begin
      // Stream assignments
      stream_array_a_dly0[n] <= buff2_str [n*DWIDTH +: DWIDTH] ; // 2 Line Delay 
      stream_array_b_dly0[n] <= buff1_str [n*DWIDTH +: DWIDTH] ; // 1 Line Delay
      stream_array_c_dly0[n] <= data_in   [n*DWIDTH +: DWIDTH] ; // Current Line
      // 1 and 2 pixel Delays
      stream_array_a_dly1[n] <= stream_array_a_dly0[n] ;
      stream_array_b_dly1[n] <= stream_array_b_dly0[n] ;
      stream_array_c_dly1[n] <= stream_array_c_dly0[n] ;
      stream_array_a_dly2[n] <= stream_array_a_dly1[n] ;
      stream_array_b_dly2[n] <= stream_array_b_dly1[n] ;
      stream_array_c_dly2[n] <= stream_array_c_dly1[n] ;
    end

  end
end


logic        [$clog2(ROWS)-1:0] row_cnt    ;
logic [$clog2(COLS/PIXCNT)-1:0] col_cnt    ; 
logic [$clog2(COLS/PIXCNT)-1:0] col_cnt_1  ; 
logic [$clog2(COLS/PIXCNT)-1:0] col_full   ;
logic                     [3:0] bypass     ; // Bypass Select: bit 0 (top), bit 1 (bottom), bit 2 (left), bit 3 (right)
logic                     [3:0] bypass_dly ;
logic                           purge      ;

assign col_full = cols[$clog2(COLS)-1:PIXCNTBITS]-1'b1;

always_ff @ (posedge clk or posedge reset) begin
  if (reset) begin
    row_cnt    <= '0 ;
    col_cnt    <= '0 ;
    col_cnt_1  <= '0 ; 
    bypass     <= '0 ;
    bypass_dly <= '0 ;
    end 
  else begin
    if (data_vld)
       col_cnt_1 <= col_cnt_1 + 1'b1;
    
    if (stream_vld)     
       col_cnt <= (col_cnt == col_full) ? '0 : col_cnt + 1'b1 ;

    if ((col_cnt == col_full) && stream_vld)
      row_cnt <= row_cnt + 1'b1 ;     

      
   //  Bypass Control (Edges of image frame)
    bypass[0] <= (row_cnt == '0) | bypass_filt ? 1'b1 : 1'b0 ; // Top row (bypass top) 
    bypass[1] <= (row_cnt == rows-1'b1)  | bypass_filt ? 1'b1 : 1'b0 ; // Bottom row (bypass bottom)
    
    bypass[2] <= (col_cnt == '0)       | bypass_filt ? 1'b1 : 1'b0 ; // first column (bypass left)
    bypass[3] <= (col_cnt == col_full) | bypass_filt ? 1'b1 : 1'b0 ; // last  column (bypass right)
    
    bypass_dly <= bypass ; // delayed to line up with mask pixels
  end
end

//------------------------------------------------
// Data Valid output delays (System Pipeline delay)
//------------------------------------------------
logic [4:0] vld_dly ;

assign purge      = (row_cnt == rows-1'b1); 
assign stream_vld = (data_vld & buff1_full) | purge ; // Data is valid out of the line buffers
assign data_out   = filt_data_out ;    
assign out_vld    = vld_dly[4] ;
always_ff @ (posedge clk or posedge reset) begin
  if (reset) begin
    vld_dly  <= '0 ;
  end else begin
    // 3 clk pipeline in calculation, 2 clk delay in stream_array assignment
    vld_dly <= {vld_dly[3:0],stream_vld} ;
  end
end


// Array Assignments for Sweeping window:
// ---------------------------------------------------------------------------------
//     stream dly 2             stream dly 1             stream dly 0
//  _______________________  _______________________  _______________________
// |__|__|__|__|__|__|__|__||__|__|__|__|__|__|__|__||__|__|__|__|__|__|__|__|
//  7  6  5  4  3  2  1  0   7  6  5  4  3  2  1  0   7  6  5  4  3  2  1  0
//                       \_____________________________/ 
//    pix array          |__|__|__|__|__|__|__|__|__|__|             
//                        9  8  7  6  5  4  3  2  1  0  
//
//                               8x window sweep
//                        ________ 
//               j=1     |__|__|__| ---->  ---->  ---->|
//                        a  b  c  
//                           ________
//               j=2        |__|__|__| -->  ----> ---->|
//                           a  b  c
//                              ...            ________
//               j=9                          |__|__|__|                                                     
//                                             a  b  c
// ---------------------------------------------------------------------------------


logic [DWIDTH-1:0] pix_array_a [0:9] ;
logic [DWIDTH-1:0] pix_array_b [0:9] ;
logic [DWIDTH-1:0] pix_array_c [0:9] ;

assign pix_array_a  [0]  = stream_array_a_dly0  [7]  ;
assign pix_array_b  [0]  = stream_array_b_dly0  [7]  ;          
assign pix_array_c  [0]  = stream_array_c_dly0  [7]  ;     // was [0] dly0[7]      

assign pix_array_a [1:8] = stream_array_a_dly1 [0:7] ;
assign pix_array_b [1:8] = stream_array_b_dly1 [0:7] ;          
assign pix_array_c [1:8] = stream_array_c_dly1 [0:7] ; 

assign pix_array_a  [9]  = stream_array_a_dly2  [0]  ; 
assign pix_array_b  [9]  = stream_array_b_dly2  [0]  ;           
assign pix_array_c  [9]  = stream_array_c_dly2  [0]  ;     // was [9] dly2[0]      


genvar j;
generate
for (j=1; j<9; j=j+1) 
begin : filter

// The Filter convolution Window:  
// ----------------------------------------
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


filter_3x3_mask
 #( .DWIDTH   ( DWIDTH )) 
filt_window
  ( .clk      ( clk )
  , .bypass   ( bypass_dly )
  , .data_a   (pix_array_a[j+1]) , .data_b (pix_array_a[j]) , .data_c (pix_array_a[j-1])
  , .data_d   (pix_array_b[j+1]) , .data_e (pix_array_b[j]) , .data_f (pix_array_b[j-1])
  , .data_g   (pix_array_c[j+1]) , .data_h (pix_array_c[j]) , .data_i (pix_array_c[j-1])
  , .data_out (filt_data_out[(j-1)*DWIDTH +: DWIDTH])
  ) ;

end : filter
endgenerate

// row buffer using shift register 
always @ (posedge clk or posedge reset) begin
   if (reset)
      buff1_full <= '0;
   else if (col_cnt_1 == col_full)
      buff1_full <= '1;
end

line_buffer_8pix line_buff1 
(
    .tap_N(col_full + 1'b1),
    .D(data_in),
    .clk(clk),
	 .rst(reset),
    .enable(data_vld | purge ),
    .Q(buff1_str)
);

line_buffer_8pix line_buff2
(
    .tap_N(col_full + 1'b1),
    .D(buff1_str),
    .clk(clk),
	 .rst(reset),
    .enable(data_vld | purge ),
    .Q(buff2_str)
);


endmodule

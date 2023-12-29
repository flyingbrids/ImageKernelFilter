//*******************************************************************************************
//**
//**  File Name          : filter_5x5.sv (SystemVerilog)
//**  Module Name        : filter_5x5
//**                     :
//**  Module Description : 5x5 Kernel 2D Filter
//**                     : This module is a 2D smoothing (Low pass) filter that takes in
//**                     : a raster stream of data and outputs a filtered stream of data.
//**                     :
//**  Author             : Leon Shen
//**                     :
//**  Creation Date      : 12/28/2023
//**                     : 
//**  Version History    :
//**                     :
//**
//*******************************************************************************************
 module filter_5x5
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

logic [DWIDTH*PIXCNT-1:0] filt_data_out5x5 ;
logic [DWIDTH*PIXCNT-1:0] buff1_str  ;
logic [DWIDTH*PIXCNT-1:0] buff2_str  ;
logic [DWIDTH*PIXCNT-1:0] buff3_str  ;
logic [DWIDTH*PIXCNT-1:0] buff4_str  ;
logic                     buff1_full ;
logic                     buff2_full ;

logic  [DWIDTH-1:0] stream_array_a_dly0 [0:PIXCNT-1] ;
logic  [DWIDTH-1:0] stream_array_b_dly0 [0:PIXCNT-1] ;
logic  [DWIDTH-1:0] stream_array_c_dly0 [0:PIXCNT-1] ;
logic  [DWIDTH-1:0] stream_array_d_dly0 [0:PIXCNT-1] ;
logic  [DWIDTH-1:0] stream_array_e_dly0 [0:PIXCNT-1] ;

logic  [DWIDTH-1:0] stream_array_a_dly1 [0:PIXCNT-1] ;
logic  [DWIDTH-1:0] stream_array_b_dly1 [0:PIXCNT-1] ;
logic  [DWIDTH-1:0] stream_array_c_dly1 [0:PIXCNT-1] ;
logic  [DWIDTH-1:0] stream_array_d_dly1 [0:PIXCNT-1] ;
logic  [DWIDTH-1:0] stream_array_e_dly1 [0:PIXCNT-1] ;

logic  [DWIDTH-1:0] stream_array_a_dly2 [0:PIXCNT-1] ;
logic  [DWIDTH-1:0] stream_array_b_dly2 [0:PIXCNT-1] ;
logic  [DWIDTH-1:0] stream_array_c_dly2 [0:PIXCNT-1] ;
logic  [DWIDTH-1:0] stream_array_d_dly2 [0:PIXCNT-1] ;
logic  [DWIDTH-1:0] stream_array_e_dly2 [0:PIXCNT-1] ;

logic stream_vld, reset;
assign reset = new_frame | rst;

//------------------------------------------------
// Stream Assignments and Pixel delay
//------------------------------------------------
always_ff @ (posedge clk or posedge reset) begin
  if (reset) begin
    stream_array_a_dly0 <= '{default:0};
    stream_array_b_dly0 <= '{default:0};
    stream_array_c_dly0 <= '{default:0};
    stream_array_d_dly0 <= '{default:0};
    stream_array_e_dly0 <= '{default:0};	 
    stream_array_a_dly1 <= '{default:0};
    stream_array_b_dly1 <= '{default:0};
    stream_array_c_dly1 <= '{default:0};
    stream_array_d_dly1 <= '{default:0};
    stream_array_e_dly1 <= '{default:0};	 
    stream_array_a_dly2 <= '{default:0};
    stream_array_b_dly2 <= '{default:0};
    stream_array_c_dly2 <= '{default:0};
    stream_array_d_dly2 <= '{default:0};
    stream_array_e_dly2 <= '{default:0};	 
  end else begin
    
    for (int n=0; n<PIXCNT; n++) begin
      // Stream assignments
      stream_array_a_dly0[n] <= buff4_str [n*DWIDTH +: DWIDTH] ; 
      stream_array_b_dly0[n] <= buff3_str [n*DWIDTH +: DWIDTH] ; 
      stream_array_c_dly0[n] <= buff2_str [n*DWIDTH +: DWIDTH] ; 
	  stream_array_d_dly0[n] <=  buff1_str [n*DWIDTH +: DWIDTH] ; 
      stream_array_e_dly0[n] <= data_in   [n*DWIDTH +: DWIDTH] ; 
      // 1 and 2 pixel Delays
      stream_array_a_dly1[n] <= stream_array_a_dly0[n] ;
      stream_array_b_dly1[n] <= stream_array_b_dly0[n] ;
      stream_array_c_dly1[n] <= stream_array_c_dly0[n] ;
      stream_array_d_dly1[n] <= stream_array_d_dly0[n] ;
      stream_array_e_dly1[n] <= stream_array_e_dly0[n] ;		
      stream_array_a_dly2[n] <= stream_array_a_dly1[n] ;
      stream_array_b_dly2[n] <= stream_array_b_dly1[n] ;
      stream_array_c_dly2[n] <= stream_array_c_dly1[n] ;
      stream_array_d_dly2[n] <= stream_array_d_dly1[n] ;
      stream_array_e_dly2[n] <= stream_array_e_dly1[n] ;		
    end

  end
end


//---------------------------------------------------
// Row and Column Counter (for bypass control)
// Note: This pixels counts after the buffer stages
//---------------------------------------------------
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
	 buff1_full <= '0 ;
    buff2_full <= '0 ;
  end 
  else begin
    if (data_vld)
	    col_cnt_1 <= col_cnt_1 == col_full? '0 : col_cnt_1 + 1'b1;
    
	 if ((col_cnt_1 == col_full-1'b1) & data_vld ) begin
	    buff1_full <= '1;
		 buff2_full <= buff1_full;
    end 	 
  
    //----
    if (stream_vld)     
      col_cnt <= col_cnt == col_full? '0 : col_cnt + 1'b1 ;
    //----  
    if (col_cnt == col_full && stream_vld)
      row_cnt <= row_cnt + 1'b1 ;
      
    // Bypass Control (Edges of image frame)
    bypass[0] <= (row_cnt == 0)           | bypass_filt ? 1'b1 : 1'b0 ; // Top row (bypass top) 
    bypass[1] <= (row_cnt == rows- 1'b1)  | (row_cnt == rows - 2'd2) | bypass_filt ? 1'b1 : 1'b0 ; // Bottom row (bypass bottom)
    
    bypass[2] <= (col_cnt == '0)          | bypass_filt ? 1'b1 : 1'b0 ; // first column (bypass left)
    bypass[3] <= (col_cnt == col_full)    | bypass_filt ? 1'b1 : 1'b0 ; // last  column (bypass right)
    
    bypass_dly <= bypass ; // delayed to line up with mask pixels
  end
end

//------------------------------------------------
// Data Valid output delays (System Pipeline delay)
//------------------------------------------------
logic [4:0] vld_dly ;

assign purge      = (row_cnt == rows- 1'b1)  | (row_cnt == rows - 2'd2) ;
assign stream_vld = (data_vld & buff2_full) | purge ; // Data is valid out of the line buffers
assign data_out   = filt_data_out5x5;
always_ff @ (posedge clk or posedge reset) begin
  if (reset) begin
    vld_dly  <= '0 ;
    out_vld  <= '0 ;
  end else begin
    // 4 clk pipeline in calculation, 2 clk delay in stream_array assignment
    vld_dly <= {vld_dly[3:0],stream_vld} ;
    out_vld <= vld_dly[4];
  end
end
 
// Array Assignments for Sweeping window 5x5:
// ---------------------------------------------------------------------------------
//     stream dly 2             stream dly 1             stream dly 0
//  _______________________  _______________________  _______________________
// |__|__|__|__|__|__|__|__||__|__|__|__|__|__|__|__||__|__|__|__|__|__|__|__|
//  7  6  5  4  3  2  1  0   7  6  5  4  3  2  1  0   7  6  5  4  3  2  1  0
//                      \________________________________/ 
//    pix array         |__|__|__|__|__|__|__|__|__|__|__|             
//                      11	10	9  8  7  6  5  4  3  2  1  0  
//
//                               8x window sweep
//                        _______________ 
//               j=1     |__|__|__|__|__| ---->  ---->  ---->|
//                        a  b  c  d  e
//                           _______________
//               j=2        |__|__|__|__|__|  ----> ---->|
//                            a  b  c  d  e
//                              ...            _______________
//               j=9                          |__|__|__|__|__|                                                     
//                                             a  b  c  d  e
// ---------------------------------------------------------------------------------

logic [DWIDTH-1:0] pix_array_a_ [0:11] ;
logic [DWIDTH-1:0] pix_array_b_ [0:11] ;
logic [DWIDTH-1:0] pix_array_c_ [0:11] ;
logic [DWIDTH-1:0] pix_array_d_ [0:11] ;
logic [DWIDTH-1:0] pix_array_e_ [0:11] ;

assign pix_array_a_  [0:1]  = stream_array_a_dly0  [6:7]  ;
assign pix_array_b_  [0:1]  = stream_array_b_dly0  [6:7]  ;          
assign pix_array_c_  [0:1]  = stream_array_c_dly0  [6:7]  ;     // was [0] dly0[7]      
assign pix_array_d_  [0:1]  = stream_array_d_dly0  [6:7]  ;          
assign pix_array_e_  [0:1]  = stream_array_e_dly0  [6:7]  ;     // was [0] dly0[7]  
  
assign pix_array_a_ [2:9] = stream_array_a_dly1 [0:7] ;
assign pix_array_b_ [2:9] = stream_array_b_dly1 [0:7] ;          
assign pix_array_c_ [2:9] = stream_array_c_dly1 [0:7] ; 
assign pix_array_d_ [2:9] = stream_array_d_dly1 [0:7] ;          
assign pix_array_e_ [2:9] = stream_array_e_dly1 [0:7] ; 

assign pix_array_a_  [10:11]  = stream_array_a_dly2  [0:1]  ; 
assign pix_array_b_  [10:11]  = stream_array_b_dly2  [0:1]  ;           
assign pix_array_c_  [10:11]  = stream_array_c_dly2  [0:1]  ;     // was [9] dly2[0]      
assign pix_array_d_  [10:11]  = stream_array_d_dly2  [0:1]  ;           
assign pix_array_e_  [10:11]  = stream_array_e_dly2  [0:1]  ;     // was [9] dly2[0] 


genvar j;
generate
for (j=1; j<9; j=j+1) 
begin : filter

// The Filter 5*5 convolution Window:  
// ----------------------------------------
// ______________________________________________________________
// |           |           |           |           |           |
// |   data a  |   data b  |   data c  |   data d  |   data e  |
// |   (x1)    |   (x4)    |   (x6)    |   (x4)    |   (x1)    |
// |___________|___________|___________|___________|___________|
// |           |           |           |           |           |
// |   data f  |   data g  |   data h  |   data i  |   data j  |
// |   (x4)    |   (x16)   |   (x24)   |   (x16)   |   (x4)    |  
// |___________|___________|___________|___________|___________|
// |           |           |           |           |           |
// |   data k  |   data l  |   data m  |   data n  |   data o  |  
// |   (x6)    |   (x24)   |   (x36)   |   (x24)   |   (x6)    |
// |___________|___________|___________|___________|___________|
// |           |           |           |           |           |
// |   data p  |   data q  |   data r  |   data s  |   data t  |
// |   (x4)    |   (x16)   |   (x24)   |   (x16)   |   (x4)    |  
// |___________|___________|___________|___________|___________|
// |           |           |           |           |           |
// |   data u  |   data v  |   data w  |   data x  |   data y  |  
// |   (x1)    |   (x4)    |   (x6)    |   (x4)    |   (x1)    |
// |___________|___________|___________|___________|___________|
   
filter_5x5_mask
 #( .DWIDTH   ( DWIDTH )) 
filt_window1
  ( .clk      ( clk )
  , .bypass   ( bypass_dly )
  , .kernelSelect ('0)
  , .data_a   (pix_array_a_[j+3]) , .data_b (pix_array_a_[j+2]) , .data_c (pix_array_a_[j+1]), .data_d (pix_array_a_[j]) , .data_e (pix_array_a_[j-1])
  , .data_f   (pix_array_b_[j+3]) , .data_g (pix_array_b_[j+2]) , .data_h (pix_array_b_[j+1]), .data_i (pix_array_b_[j]) , .data_j (pix_array_b_[j-1])
  , .data_k   (pix_array_c_[j+3]) , .data_l (pix_array_c_[j+2]) , .data_m (pix_array_c_[j+1]), .data_n (pix_array_c_[j]) , .data_o (pix_array_c_[j-1])
  , .data_p   (pix_array_d_[j+3]) , .data_q (pix_array_d_[j+2]) , .data_r (pix_array_d_[j+1]), .data_s (pix_array_d_[j]) , .data_t (pix_array_d_[j-1])
  , .data_u   (pix_array_e_[j+3]) , .data_v (pix_array_e_[j+2]) , .data_w (pix_array_e_[j+1]), .data_x (pix_array_e_[j]) , .data_y (pix_array_e_[j-1])  
  , .data_out (filt_data_out5x5[(j-1)*DWIDTH +: DWIDTH])
  ) ; 
  

end : filter
endgenerate


//--------------------------------------------------------
// Line Buffers    
// ( Data streams in 8 pixels at a time for 2048 total)
// -------------------------------------------------------
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

line_buffer_8pix line_buff3 
(
    .tap_N(col_full + 1'b1),
    .D(buff2_str),
    .clk(clk),
	 .rst(reset),
    .enable(data_vld | purge ),
    .Q(buff3_str)
);

line_buffer_8pix line_buff4
(
    .tap_N(col_full + 1'b1),
    .D(buff3_str),
    .clk(clk),
	 .rst(reset),
    .enable(data_vld | purge ),
    .Q(buff4_str)
);
  
endmodule

 
//*******************************************************************************************
//**
//**  File Name          : non_max_suppression.sv (SystemVerilog)
//**  Module Name        : non_max_suppression
//**                     :
//**  Module Description : Depending on the gradient direction, compare the gradient magnitutde
//**                     : with its adjacent counterparts to filter out non-maximal candidates
//**  Author             : Leon Shen
//**                     :
//**  Creation Date      : 12/28/2023
//**                     : 
//**  Version History    :
//**                     :
//**
//*******************************************************************************************
module non_max_suppression
  #( 
    parameter                        MAG_WIDTH = 13
  , parameter                        DIR_WIDTH = 3 
  , parameter                             COLS = 2448 
  , parameter                             ROWS = 2048
  , parameter                           PIXCNT = 8 
  )
  ( input   logic                                    clk
  , input   logic                                    rst
  , input   logic                                    bypass_filt
  , input   logic [$clog2(ROWS)-1:0]                 rows
  , input   logic [$clog2(COLS)-1:0]                 cols 
  , input   logic                                    new_frame
  , input   logic [(DIR_WIDTH+MAG_WIDTH)*PIXCNT-1:0] grad_in
  , input   logic [PIXCNT-1:0]                       mask_in
  , input   logic                                    data_vld
  , output  logic [MAG_WIDTH*PIXCNT-1:0]             data_out 
  , output  logic                                    out_vld
  , output  logic [PIXCNT-1:0]                       mask_out                  
  ) ;

localparam GRAD_WIDTH = DIR_WIDTH + MAG_WIDTH;
localparam BUF_WIDTH  = GRAD_WIDTH + 1;

logic [BUF_WIDTH*PIXCNT-1:0] lbuf1_stream  ;
logic [BUF_WIDTH*PIXCNT-1:0] lbuf2_stream  ;
logic                     buff1_full ;
logic                     buff2_full ;

logic  [BUF_WIDTH-1:0] stream_array_a_dly0 [0:PIXCNT-1] ;
logic  [BUF_WIDTH-1:0] stream_array_b_dly0 [0:PIXCNT-1] ;
logic  [BUF_WIDTH-1:0] stream_array_c_dly0 [0:PIXCNT-1] ;

logic  [BUF_WIDTH-1:0] stream_array_a_dly1 [0:PIXCNT-1] ;
logic  [BUF_WIDTH-1:0] stream_array_b_dly1 [0:PIXCNT-1] ;
logic  [BUF_WIDTH-1:0] stream_array_c_dly1 [0:PIXCNT-1] ;

logic  [BUF_WIDTH-1:0] stream_array_a_dly2 [0:PIXCNT-1] ;
logic  [BUF_WIDTH-1:0] stream_array_b_dly2 [0:PIXCNT-1] ;
logic  [BUF_WIDTH-1:0] stream_array_c_dly2 [0:PIXCNT-1] ;

logic stream_vld;

logic [BUF_WIDTH*PIXCNT-1:0] data_in ;

wire  reset = rst | new_frame ;

genvar k;
generate
for (k=0; k<PIXCNT; k=k+1) 
begin : pack_array
  assign data_in [BUF_WIDTH*k +: BUF_WIDTH] = { mask_in[k], grad_in[GRAD_WIDTH*k +: GRAD_WIDTH] };  
end : pack_array
endgenerate

//------------------------------------------------
// Stream Assignments and Pixel delay
//------------------------------------------------
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
      stream_array_a_dly0[n] <= lbuf2_stream [n*BUF_WIDTH +: BUF_WIDTH] ; // 2 Line Delay 
      stream_array_b_dly0[n] <= lbuf1_stream [n*BUF_WIDTH +: BUF_WIDTH] ; // 1 Line Delay
      stream_array_c_dly0[n] <= data_in      [n*BUF_WIDTH +: BUF_WIDTH] ; // Current Line
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

//---------------------------------------------------
// Row and Column Counter (for bypass control)
// Note: This pixels counts after the buffer stages
//---------------------------------------------------
// Bypass Select Note:
// bit 0: bypass top of window
// bit 1: bypass bottom of window
// bit 2: bypass left of window
// bit 3: bypass right of window 

logic [$clog2(ROWS)-1:0]        row_cnt    ;
logic [$clog2(COLS/PIXCNT)-1:0] col_cnt    ; 
logic [$clog2(COLS/PIXCNT)-1:0] col_cnt_1  ; 
logic [$clog2(COLS/PIXCNT)-1:0] col_full   ;
logic  [3:0] bypass     ; // Bypass Select: bit 0 (top), bit 1 (bottom), bit 2 (left), bit 3 (right)
logic  [3:0] bypass_dly ;
logic        purge      ;
localparam         PIXCNTBITS  = $clog2(PIXCNT);
assign col_full = cols[$clog2(COLS)-1:PIXCNTBITS]-1'b1;

always_ff @ (posedge clk or posedge reset) begin
  if (reset) begin
    row_cnt    <= '0 ;
    col_cnt    <= '0 ;
	col_cnt_1  <= '0 ;
    bypass     <= '0 ;
    bypass_dly <= '0 ;
    buff1_full <= '0;
    buff2_full <= '0;
  end else begin
     if (data_vld)
       col_cnt_1 <= col_cnt_1 + 1;
     
     if (col_cnt_1 == col_full) begin
       buff1_full <= '1;
       buff2_full <= buff1_full;
     end 
    //----
    if (stream_vld)     
      col_cnt <= col_cnt == col_full? '0 : col_cnt + 1'b1 ;
    //----  
    if ((col_cnt == col_full) && stream_vld)
      row_cnt <= row_cnt + 1'b1 ;

      // Bypass Control (Edges of image frame)
    bypass[0] <= (row_cnt == '0)        | bypass_filt ? 1'b1 : 1'b0 ; // Top row (bypass top) 
    bypass[1] <= (row_cnt == rows-1'b1) | bypass_filt ? 1'b1 : 1'b0 ; // Bottom row (bypass bottom)
    
    bypass[2] <= (col_cnt == '0)        | bypass_filt ? 1'b1 : 1'b0 ; // first column (bypass left)
    bypass[3] <= (col_cnt == col_full)  | bypass_filt ? 1'b1 : 1'b0 ; // last  column (bypass right)
    
    bypass_dly <= bypass ; // delayed to line up with mask pixels
  end
end

//------------------------------------------------
// Data Valid output delays (System Pipeline delay)
//------------------------------------------------
logic [2:0] vld_dly ;

assign purge      = (row_cnt == rows-1'b1); 
assign stream_vld = (data_vld & buff1_full) | purge ; // Data is valid out of the line buffers
assign out_vld    = vld_dly[2] ;

always_ff @ (posedge clk or posedge reset) begin
  if (reset) begin
    vld_dly  <= '0 ;
  end else begin
    // 1 clk pipeline in calculation, 2 clk delay in mag_array assignment
    vld_dly <= {vld_dly[1:0],stream_vld} ;
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


logic [BUF_WIDTH-1:0] pix_array_a [0:9] ;
logic [BUF_WIDTH-1:0] pix_array_b [0:9] ;
logic [BUF_WIDTH-1:0] pix_array_c [0:9] ;

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

// The non-maximum suppression 3x3 Window:  
// -------------------------------------------
// __________________________________
// |          |          |          |
// |  pix(a)  |  pix(b)  |  pix(c)  | 
// |__________|__________|__________|
// |          |          |          |
// |  pix(d)  |  pix(e)  |  pix(f)  |
// |__________|__________|__________|
// |          |          |          |
// |  pix(g)  |  pix(h)  |  pix(i)  |  
// |__________|__________|__________|

nms_3x3_mask
 #( 
    .DWIDTH          ( BUF_WIDTH )
  , .MAG_WIDTH       ( MAG_WIDTH )
  , .DIR_WIDTH       ( DIR_WIDTH )
   ) 
nms_3x3_mask_i
  ( .clk      ( clk )
  , .bypass   ( bypass  )
  , .data_a   (pix_array_a[j+1]) , .data_b (pix_array_a[j]) , .data_c (pix_array_a[j-1])
  , .data_d   (pix_array_b[j+1]) , .data_e (pix_array_b[j]) , .data_f (pix_array_b[j-1])
  , .data_g   (pix_array_c[j+1]) , .data_h (pix_array_c[j]) , .data_i (pix_array_c[j-1])
  , .data_out (data_out[(j-1)*MAG_WIDTH +: MAG_WIDTH])
  , .mask_out (mask_out[j-1])
  ) ;

end : filter
endgenerate


//--------------------------------------------------------
// Line Buffers    
// ( Data streams in 8 pixels at a time)
// -------------------------------------------------------
wire buff1_rden = (buff1_full & data_vld) | purge ;
wire buff2_rden = (buff2_full & data_vld) | purge ;
wire buff2_wren = (buff1_full & data_vld) ;

line_buffer_8pix 
#(
    .DWIDTH (BUF_WIDTH)
 )
 line_buff1 
(
    .tap_N(col_full + 1'b1),
    .D(data_in),
    .clk(clk),
	 .rst(reset),
    .enable(data_vld | purge ),
    .Q(lbuf1_stream)
);

line_buffer_8pix 
#(
    .DWIDTH (BUF_WIDTH)
 )
 line_buff2 
(
    .tap_N(col_full + 1'b1),
    .D(lbuf1_stream),
    .clk(clk),
	 .rst(reset),
    .enable(data_vld | purge ),
    .Q(lbuf2_stream)
);

endmodule



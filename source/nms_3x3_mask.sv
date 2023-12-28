//*******************************************************************************************
//**
//**  File Name          : nms_3x3_mask.sv (SystemVerilog)
//**  Module Name        : nms_3x3_mask
//**                     :
//**  Module Description : maximal mask generating kernel
//**                     : 
//**                     : 
//**                     : 
//**                     :
//**  Author             : Leon Shen
//**                     :
//**  Creation Date      : 12/8/2023
//**                     : 
//**  Version History    :
//**                     :
//**
//*******************************************************************************************
module nms_3x3_mask
  #( 
    parameter                 DWIDTH = 16 
  , parameter              MAG_WIDTH = 12
  , parameter              DIR_WIDTH =  2
  )
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
  , output logic [MAG_WIDTH-1:0] data_out
  , output logic              mask_out
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

logic [MAG_WIDTH-1:0] mag_a ;
logic [MAG_WIDTH-1:0] mag_b ;
logic [MAG_WIDTH-1:0] mag_c ;
logic [MAG_WIDTH-1:0] mag_d ;
logic [MAG_WIDTH-1:0] mag_e ;
logic [MAG_WIDTH-1:0] mag_f ;
logic [MAG_WIDTH-1:0] mag_g ;
logic [MAG_WIDTH-1:0] mag_h ;
logic [MAG_WIDTH-1:0] mag_i ;

logic [DIR_WIDTH-1:0] dir_e ; 
logic [MAG_WIDTH-1:0] mag_out ;
logic mask_e;

// IO connection
assign data_out = mag_out;
assign mask_e = data_e[DWIDTH-1]; 

assign mag_a  = bypass[0] | bypass[2] ? '0: data_a[MAG_WIDTH-1:0] ;
assign mag_b  = bypass[0]             ? '0: data_b[MAG_WIDTH-1:0] ;          
assign mag_c  = bypass[0] | bypass[3] ? '0: data_c[MAG_WIDTH-1:0] ;          
assign mag_d  = bypass[2]             ? '0: data_d[MAG_WIDTH-1:0] ;
assign mag_e  =                                 data_e[MAG_WIDTH-1:0] ;
assign mag_f  = bypass[3]             ? '0: data_f[MAG_WIDTH-1:0] ;
assign mag_g  = bypass[1] | bypass[2] ? '0: data_g[MAG_WIDTH-1:0] ;
assign mag_h  = bypass[1]             ? '0: data_h[MAG_WIDTH-1:0] ;
assign mag_i  = bypass[1] | bypass[3] ? '0: data_i[MAG_WIDTH-1:0] ;    

assign dir_e  = data_e[DIR_WIDTH+MAG_WIDTH-1:MAG_WIDTH] ;

// start non-maximal suppression here
// if sobel mask = 1 then do:
// dir=  0 degree: if mag(e)<mag(d) or mag(e)<mag(f), then mask(e)=0, else mask(e)=1
// dir= 45 degree: if mag(e)<mag(c) or mag(e)<mag(g), then mask(e)=0, else mask(e)=1
// dir= 90 degree: if mag(e)<mag(b) or mag(e)<mag(h), then mask(e)=0, else mask(e)=1
// dir=135 degree: if mag(e)<mag(a) or mag(e)<mag(i), then mask(e)=0, else mask(e)=1
always_ff @ (posedge clk) begin
 if (mask_e) begin
    case (dir_e)
      3'd0 : // 0 degree
        if ((mag_e > mag_d) | (mag_e > mag_f)) begin
          mag_out  <= mag_e;
		    mask_out <= 1'b1;
          end
        else begin
          mag_out  <=  '0; 
		    mask_out <= 1'b0;
          end
      3'd1 : // 45 degree
        if ((mag_e > mag_g) | (mag_e > mag_c)) begin
          mag_out <= mag_e;
          mask_out <= 1'b1;
          end
        else begin
          mag_out  <=  '0; 
          mask_out <= 1'b0;
          end
      3'd2 : // 90 degree
        if ((mag_e > mag_b) | (mag_e > mag_h)) begin
          mag_out <= mag_e;
          mask_out <= 1'b1;
          end
        else begin
          mag_out  <=  '0; 
          mask_out <= 1'b0;
          end
      3'd3 : // 135 degree
        if ((mag_e > mag_a) | (mag_e > mag_i)) begin
          mag_out <= mag_e;
          mask_out <= 1'b1;
          end
        else begin
          mag_out  <=  '0; 
          mask_out <= 1'b0;
          end
      3'd4 : // 180 degree
        if ((mag_e > mag_d) | (mag_e > mag_f)) begin
          mag_out  <= mag_e;
		  mask_out <= 1'b1;
          end
        else begin
          mag_out  <=  '0; 
		  mask_out <= 1'b0;
          end
      3'd5 : // 225 degree
        if ((mag_e > mag_g) | (mag_e > mag_c)) begin
          mag_out <= mag_e;
          mask_out <= 1'b1;
          end
        else begin
          mag_out  <=  '0; 
          mask_out <= 1'b0;
          end
      3'd6 : // 270 degree
        if ((mag_e > mag_b) | (mag_e > mag_h)) begin
          mag_out <= mag_e;
          mask_out <= 1'b1;
          end
        else begin
          mag_out  <=  '0; 
          mask_out <= 1'b0;
          end
      3'd7 : // 315 degree
        if ((mag_e > mag_a) | (mag_e > mag_i)) begin
          mag_out <= mag_e;
          mask_out <= 1'b1;
          end
        else begin
          mag_out  <=  '0; 
          mask_out <= 1'b0;
          end
    endcase
    end
  else begin
    mag_out  <= '0;
    mask_out <= 1'b0;
    end
  end 

endmodule



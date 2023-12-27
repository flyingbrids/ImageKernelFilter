//*******************************************************************************************
//**
//**  File Name          : gradiant.sv (SystemVerilog)
//**  Module Name        : gradiant
//**                     :
//**  Module Description : Calculate gradiant (magnitude and angle, angle is encoded by 4 bits)
//**                     : fixed point divison and LUT table for tan-1 function
//**                     : 
//**                     :
//**  Author             : Leon Shen
//**                     :
//**  Creation Date      : 8/4/2023
//**                     : 
//**  Version History    :
//**
//*******************************************************************************************
module gradiant 
  #( 
     parameter     DWIDTH = 10 
   , parameter  MAG_WIDTH = 13
   , parameter  DIR_WIDTH =  3
   , parameter    R_WIDTH = 16
   )
  (
    input  logic                            clk 
  , input  logic            [MAG_WIDTH-1:0] threshold    
  , input  logic               [DWIDTH+2:0] x                
  , input  logic               [DWIDTH+2:0] y 
  , input  logic                            mask_in  
  , output logic                            mask_out        // p17
  
  , output logic  [DIR_WIDTH+MAG_WIDTH-1:0] grad_out        // p17
  , output logic              [R_WIDTH-1:0] rad_out         // p17
  , output logic                      [1:0] quadrant_out    // p17
  , output logic        [(DWIDTH+2)+12-1:0] v_div_h_out     // p17  
  , output logic                            x_gt_y_out      // p17  
  ) ;

logic           [MAG_WIDTH-1:0] grad_mag   ; 
logic           [DIR_WIDTH-1:0] grad_dir   ;    
logic       [(DWIDTH+2)+12-1:0] v_div_h_dly [3:0] ;
logic       [(DWIDTH+2)+12-1:0] v_div_h    ;
logic        [(DWIDTH+3)*2-1:0] y_sqr  ;
logic        [(DWIDTH+3)*2-1:0] x_sqr  ;
logic        [(DWIDTH+3)*2-1:0] sum_sqr;
logic                    [14:0] x_zero ;
logic                    [14:0] y_zero ;
logic                           x_eq_y ;
logic              [DWIDTH+2:0] abs_x  ;   // +/- 12
logic              [DWIDTH+2:0] abs_y  ;   // +/- 12
logic             [DWIDTH+13:0] numer  ;   // 12.12
logic              [DWIDTH+1:0] denom  ;   // 12.0 
logic                    [14:0] x_sign ;
logic                    [14:0] y_sign ;
logic             [R_WIDTH-1:0] theta  ; 
logic                     [1:0] quadrant ; 
logic                     [1:0] quadrant_dly [2:0] ;
logic                           x_gt_y ; 
logic                    [17:0] x_gt_y_dly ; 
logic             [R_WIDTH-1:0] rad ;  
logic             [R_WIDTH-1:0] rad_dly ;  

assign abs_x = x[DWIDTH+2] ? ~x + 1'b1 : x ; 
assign abs_y = y[DWIDTH+2] ? ~y + 1'b1 : y ; 
assign x_gt_y = (abs_x > abs_y) ? 1'b1 : 1'b0 ;

assign quadrant = !x_sign[13] & !y_sign[13] ? 'd0 :   // p14
                   x_sign[13] & !y_sign[13] ? 'd1 :     
                   x_sign[13] &  y_sign[13] ? 'd2 : 'd3 ;  
						 
assign quadrant_out = quadrant_dly[2];
assign v_div_h_out  = v_div_h_dly[3];
assign x_gt_y_out   = x_gt_y_dly [16];

logic [16:0] mask_buf;
logic [25:0] root;
                   
always_ff @ (posedge clk) begin
  x_sqr    <= x*x;  // p1
  y_sqr    <= y*y;
  mask_buf <= {mask_buf[15:0],mask_in};  
  sum_sqr  <= y_sqr +  x_sqr ; // p2
  grad_mag <= root << 1; // p16
  mask_out <= (grad_mag > threshold) ? mask_buf[15] : 1'b0; // p17
  grad_out <= {grad_dir, grad_mag} ;  // p17  
	 
  x_zero[0] <= (abs_x[DWIDTH+1:0]== 0) ? 1'b1 : 1'b0 ;  // p1
  x_zero[14:1] <= {x_zero[13:1],x_zero[0]};  // p15
  y_zero[0] <= (abs_y[DWIDTH+1:0]== 0) ? 1'b1 : 1'b0 ;  // p1
  y_zero[14:1] <= {y_zero[13:1],y_zero[0]};  // p15   
  
  x_sign <= {x_sign[13:0], x[DWIDTH+2]};  // p15
  y_sign <= {y_sign[13:0], y[DWIDTH+2]};  // p15 
  x_eq_y <= v_div_h[DWIDTH+2] ; // p14   
  
  v_div_h_dly[0] <= v_div_h; // P14
  v_div_h_dly[1] <= v_div_h_dly[0];
  v_div_h_dly[2] <= v_div_h_dly[1];
  v_div_h_dly[3] <= v_div_h_dly[2];
  
  x_gt_y_dly <= {x_gt_y_dly[16:0], x_gt_y}  ; 
  
  numer <= x_gt_y ? {abs_y[DWIDTH+1:0], 12'd0} : {abs_x[DWIDTH+1:0], 12'd0} ;  // p1, 10.14
  denom <= x_gt_y ?  abs_x[DWIDTH+1:0]         :  abs_y[DWIDTH+1:0] ;          // p1, 10.2
  
  quadrant_dly [0] <= quadrant; // p16
  quadrant_dly [1] <= quadrant_dly [0];
  quadrant_dly [2] <= quadrant_dly [1];
  end

sqrt_pipeline #(.WIDTH(26))  // 13p
sqrt_int_i 
(
  .clk  (clk),  
  .rad  (sum_sqr),          // p2 
  .root (root)              // p15
);


divide_xy	divide_xy_inst   // 12 pipes 24-bit divider, denom >= numer
  (
    .clock     ( clk      )
  , .numer     ( numer    )   // p1,  10.14
  , .denom     ( denom    )	// p1,  10.2
  , .quotient  ( v_div_h  )   // p13, 1.12
  , .remain    (          )
  );

theta_lut    
theta_lut_i 
  (
	  .clock   ( clk                   ) // 
	, .address ( v_div_h[DWIDTH+2-1:0] ) // 
	, .q       ( theta                 ) // p14
  );


localparam [15:0] D_PI = 16'd51472 ;   // 2   pi, 360 degree                  
localparam [15:0]   PI = 16'd25736 ;   // 1.0 pi, 180 degree                 
localparam [15:0] H_PI = 16'd12868 ;   // 0.5 pi, 90 degree                  
localparam [15:0] Q_PI = 16'd6434  ;   // 1/4 pi, 45 degree        
localparam [15:0] O_PI = 16'd3217  ;   // 1/8 pi, 22.5 degree                 
  
always_ff @ (posedge clk) begin  // p15, offset radius
  if (x_zero[13] & y_zero[13]) 
    rad <= '0 ; 		
  else if (x_eq_y) 
    rad <= (quadrant == 2'd0) ? Q_PI : 
           (quadrant == 2'd1) ? H_PI + Q_PI : 
           (quadrant == 2'd2) ?  PI + Q_PI  : PI + H_PI + Q_PI ; 
  else if (x_gt_y_dly[13])  
    if (y_zero[13])
	   rad <= x_sign[13] ? PI : '0 ;
	 else
	   rad <= (quadrant == 2'd0) ?        theta : 
		       (quadrant == 2'd1) ?   PI - theta : 
			    (quadrant == 2'd2) ?   PI + theta : D_PI - theta ; 
  else if (x_zero[13])
    rad <= y_sign[13] ? PI + H_PI : H_PI ;
  else
    rad <= (quadrant == 2'd0) ? H_PI - theta : 
           (quadrant == 2'd1) ? H_PI + theta : 
           (quadrant == 2'd2) ? PI + H_PI - theta : PI + H_PI + theta ; 
end 

always_ff @ (posedge clk) begin  // build 4 angular region
    rad_dly <= rad ;  // p16
    rad_out <= rad_dly ;  // p17 
    if ( (rad < O_PI) || (rad >= (D_PI-O_PI)) )   // between +/- 22.5 degree
      grad_dir  <= 3'd0 ;  // 0 degree, east to west
    else if ( (rad >= (PI-O_PI)) && (rad < (PI+O_PI)) ) // between 157.5&202.5 degree
      grad_dir  <= 3'd4 ;  
    else if ( (rad >= O_PI) && (rad < (H_PI-O_PI)) )  // between +22.5&67.5 degree
      grad_dir  <= 3'd1  ; // 45 degree, north-west to south-east
    else if ( (rad >= (PI+O_PI)) && (rad < (PI+H_PI-O_PI)) )  // between +22.5&67.5 degree and 202.5&247.5 degree
      grad_dir  <= 3'd5  ; 
    else if ( (rad >= (H_PI-O_PI)) && (rad < (H_PI+O_PI)) )  // between 67.5&112.5 degree
      grad_dir  <= 3'd2  ; // 90 degree, north to south
    else if ( (rad >= (PI+H_PI-O_PI)) && (rad < (PI+H_PI+O_PI)) )  // between 247.5&292.5 degree
      grad_dir  <= 3'd6  ; 
    else if ( (rad >= (H_PI+O_PI)) && (rad < (PI-O_PI)) )  // between 112.5&157.5 degree
      grad_dir  <= 3'd3  ; // 135 degree, north-east to south-west
    else if ( (rad >= (PI+H_PI+O_PI)) && (rad < (D_PI-O_PI)) )  // between 292.5&337.5 degree
      grad_dir  <= 3'd7  ; 
  end
  
  endmodule
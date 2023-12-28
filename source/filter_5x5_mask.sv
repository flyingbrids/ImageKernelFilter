//*******************************************************************************************
//**
//**  File Name          : filter_5x5_mask.sv (SystemVerilog)
//**  Module Name        : filter_5x5_mask
//**                     :
//**  Module Description : Low Pass 5x5 calculation window for the parent module. 
//**                     : This module is a 2D smoothing (Low pass) filter that takes in
//**                     : a raster stream of data and outputs a filtered stream of data.
//**                     : Edge cases on the image are taken care of with the bypass signals
//**                     : This module also has 2 kernel coffecient selectable by parent module
//**  Author             : Leon Shen
//**  Email              : 
//**  Phone              : 
//**                     :
//**  Creation Date      : 4/16/2021
//**                     : 
//**  Version History    :
//**                     :
//**
//*******************************************************************************************


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
 
 
module filter_5x5_mask
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
       , input  logic [DWIDTH-1:0] data_j
       , input  logic [DWIDTH-1:0] data_k
       , input  logic [DWIDTH-1:0] data_l
       , input  logic [DWIDTH-1:0] data_m
       , input  logic [DWIDTH-1:0] data_n
       , input  logic [DWIDTH-1:0] data_o
       , input  logic [DWIDTH-1:0] data_p
       , input  logic [DWIDTH-1:0] data_q
       , input  logic [DWIDTH-1:0] data_r    
       , input  logic [DWIDTH-1:0] data_s
       , input  logic [DWIDTH-1:0] data_t
       , input  logic [DWIDTH-1:0] data_u
       , input  logic [DWIDTH-1:0] data_v
       , input  logic [DWIDTH-1:0] data_w
       , input  logic [DWIDTH-1:0] data_x
       , input  logic [DWIDTH-1:0] data_y
		 , input  logic [2:0] kernelSelect
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
logic [DWIDTH-1:0] pix_j ;
logic [DWIDTH-1:0] pix_k ;
logic [DWIDTH-1:0] pix_l ;
logic [DWIDTH-1:0] pix_m ;
logic [DWIDTH-1:0] pix_n ;
logic [DWIDTH-1:0] pix_o ;
logic [DWIDTH-1:0] pix_p ;
logic [DWIDTH-1:0] pix_q ;
logic [DWIDTH-1:0] pix_r ;
logic [DWIDTH-1:0] pix_s ;
logic [DWIDTH-1:0] pix_t ;
logic [DWIDTH-1:0] pix_u ;
logic [DWIDTH-1:0] pix_v ;
logic [DWIDTH-1:0] pix_w ;
logic [DWIDTH-1:0] pix_x ;
logic [DWIDTH-1:0] pix_y ;

// Bypass Select Note:
// bit 0: bypass top of window
// bit 1: bypass bottom of window
// bit 2: bypass left of window
// bit 3: bypass right of window 
//always_comb begin
//  pix_a = bypass[0] | bypass[2] ? data_m : data_a ;
//  pix_b = bypass[0] | bypass[2] ? data_m : data_b ;
//  pix_c = bypass[0]             ? data_m : data_c ;
//  pix_d = bypass[0] | bypass[3] ? data_m : data_d ;
//  pix_e = bypass[0] | bypass[3] ? data_m : data_e ;   
//  pix_f = bypass[0] | bypass[2] ? data_m : data_f ;
//  pix_g = bypass[0] | bypass[2] ? data_m : data_g ;
//  pix_h = bypass[0]             ? data_m : data_h ;
//  pix_i = bypass[0] | bypass[3] ? data_m : data_i ;
//  pix_j = bypass[0] | bypass[3] ? data_m : data_j ;
//  pix_k = bypass[2]             ? data_m : data_k ;
//  pix_l = bypass[2]             ? data_m : data_l ;
//  pix_m = data_m ;
//  pix_n = bypass[3]             ? data_m : data_n ;   
//  pix_o = bypass[3]             ? data_m : data_o ;
//  pix_p = bypass[1] | bypass[2] ? data_m : data_p ;
//  pix_q = bypass[1] | bypass[2] ? data_m : data_q ;
//  pix_r = bypass[1]             ? data_m : data_r ;
//  pix_s = bypass[1] | bypass[3] ? data_m : data_s ;
//  pix_t = bypass[1] | bypass[3] ? data_m : data_t ;
//  pix_u = bypass[1] | bypass[2] ? data_m : data_u ;
//  pix_v = bypass[1] | bypass[2] ? data_m : data_v ;
//  pix_w = bypass[1]             ? data_m : data_w ;   
//  pix_x = bypass[1] | bypass[3] ? data_m : data_x ;
//  pix_y = bypass[1] | bypass[3] ? data_m : data_y ;  
//end

// Kernel 1
logic [DWIDTH+2:0] sum_a   ; // grows 3 bits
logic [DWIDTH+3:0] sum_b   ; // grows 4 bits
logic [DWIDTH+5:0] sum_c   ; // grows 6 bits
logic [DWIDTH+3:0] sum_d   ; // grows 4 bits
logic [DWIDTH+2:0] sum_e   ; // grows 3 bits
logic [DWIDTH+5:0] sum_all ; // grows 6 bits

always_ff @ (posedge clk) begin  
  //1p
  pix_a <= bypass[0] | bypass[2] ? data_m : data_a ; 
  pix_b <= bypass[0] | bypass[2] ? data_m : data_b ;
  pix_c <= bypass[0]             ? data_m : data_c ;
  pix_d <= bypass[0] | bypass[3] ? data_m : data_d ;
  pix_e <= bypass[0] | bypass[3] ? data_m : data_e ;   
  pix_f <= bypass[0] | bypass[2] ? data_m : data_f ;
  pix_g <= bypass[0] | bypass[2] ? data_m : data_g ;
  pix_h <= bypass[0]             ? data_m : data_h ;
  pix_i <= bypass[0] | bypass[3] ? data_m : data_i ;
  pix_j <= bypass[0] | bypass[3] ? data_m : data_j ;
  pix_k <= bypass[2]             ? data_m : data_k ;
  pix_l <= bypass[2]             ? data_m : data_l ;
  pix_m <= data_m ;
  pix_n <= bypass[3]             ? data_m : data_n ;   
  pix_o <= bypass[3]             ? data_m : data_o ;
  pix_p <= bypass[1] | bypass[2] ? data_m : data_p ;
  pix_q <= bypass[1] | bypass[2] ? data_m : data_q ;
  pix_r <= bypass[1]             ? data_m : data_r ;
  pix_s <= bypass[1] | bypass[3] ? data_m : data_s ;
  pix_t <= bypass[1] | bypass[3] ? data_m : data_t ;
  pix_u <= bypass[1] | bypass[2] ? data_m : data_u ;
  pix_v <= bypass[1] | bypass[2] ? data_m : data_v ;
  pix_w <= bypass[1]             ? data_m : data_w ;   
  pix_x <= bypass[1] | bypass[3] ? data_m : data_x ;
  pix_y <= bypass[1] | bypass[3] ? data_m : data_y ;  
  //2p
  sum_a    <=  (pix_a >> 1) +    pix_b       + (pix_c << 1) +  pix_d       +	(pix_e >> 1);   // 0.5,1,2,1,0.5                                  
  sum_b    <=   pix_f       +   (pix_g << 1) + (pix_h << 2) + (pix_i << 1) +	 pix_j      ;   // 1,2,4,2,1 
  sum_c    <=   pix_k       +   (pix_l << 3) + (pix_m << 4) + (pix_n << 3) +	 pix_o      ;   // 1,8,16,8,1
  sum_d    <=   pix_p       +   (pix_q << 1) + (pix_r << 2) + (pix_s << 1) +	 pix_t      ;   // 1,2,4,2,1 
  sum_e    <=  (pix_u >> 1) +    pix_v       + (pix_w << 1) +  pix_x       +	(pix_y >> 1);   // 0.5,1,2,1,0.5  
  //3p
  sum_all  <= sum_a + sum_b + sum_c + sum_d + sum_e ;  // Sum all            

end

 //Kernel 2
logic [DWIDTH+3:0] sum_1; // grows 4 bits
logic [DWIDTH+2:0] sum_2; // grows 3 bits
logic [DWIDTH+5:0] sum_3; // grows 6 bits
logic [DWIDTH+4:0] sum_4; // grows 5 bits
logic [DWIDTH+6:0] sum_5; // grows 7 bits
logic [DWIDTH+4:0] sum_6; // grows 5 bits
logic [DWIDTH+5:0] sum_7; // grows 6 bits
logic [DWIDTH+4:0] sum_8; // grows 5 bits
logic [DWIDTH+3:0] sum_9; // grows 4 bits
logic [DWIDTH+2:0] sum_10; // grows 3 bits
logic [DWIDTH+6:0] sum_all_1; //grow 7 bits
logic [DWIDTH+7:0] sum_all_2; //grow 8 bits
logic [DWIDTH+3:0] sum_all_3; //grow 4 bits
always_ff @ (posedge clk) begin  
  // 2p
  sum_1   <=   pix_a       +  (pix_b << 2)  + (pix_c << 2) + (pix_c << 1);
  sum_2   <=  (pix_d << 2) +	 pix_e; // 1,4,6,4,1                                 
  sum_3   <=  (pix_f << 2) +  (pix_g << 4)  + (pix_h << 4) + (pix_h << 3); 
  sum_4   <=  (pix_i << 4) +  (pix_j << 2); // 4,16,24,16,4
  sum_5   <=  (pix_k << 2) +  (pix_k << 1)  + (pix_l << 4) + (pix_l << 3)  + (pix_m << 5) + (pix_m << 2); 
  sum_6   <=  (pix_n << 4) +  (pix_n << 3)  + (pix_o << 2) + (pix_o << 1); // 6,24,36,24,6
  sum_7   <=  (pix_p << 2) +  (pix_q << 4)  + (pix_r << 4) + (pix_r << 3); 
  sum_8   <=  (pix_s << 4) +  (pix_t << 2); // 4,16,24,16,4
  sum_9   <=   pix_u       +  (pix_v << 2)  + (pix_w << 2) + (pix_w << 1);
  //3p
  sum_10  <=  (pix_x << 2) +	 pix_y; // 1,4,6,4,1    
  sum_all_1  <=   (sum_1 + sum_2 + sum_3 + sum_4);
  sum_all_2  <=   (sum_5 + sum_6 + sum_7 + sum_8);
  sum_all_3  <=   (sum_9 + sum_10);
end

// Kernel Select
always_ff @ (posedge clk) begin  
    // 4p
    if (kernelSelect == 3'd0)
        data_out <= sum_all >> 6;
	 else 
	     data_out <= (sum_all_1+sum_all_2+sum_all_3) >> 8;
end

endmodule



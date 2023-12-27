//*******************************************************************************************
//**
//**  File Name          : sqrt_pipeline.sv (SystemVerilog)
//**  Module Name        : sqrt_pipeline
//**                     :
//**  Module Description : Calculate sprt using CORDIC alogrithm. Fully pipelined design 
//**                     : pipeline stage is WIDTH/2
//**                     : 
//**                     :
//**  Author             : Leon Shen
//**                     :
//**  Creation Date      : 8/4/2023
//**                     : 
//**  Version History    :
//**
//*******************************************************************************************
module sqrt_pipeline
 #(
    parameter WIDTH = 52      // width of radicand
  ) 
  (
    input   logic   clk,    
    input   logic   [WIDTH-1:0] rad,   
    output  logic   [WIDTH-1:0] root,  // root
    output  logic   [WIDTH-1:0] rem    // remainder  
  );
    int i;
    logic [WIDTH-1:0] x [WIDTH/2-1:0]; // radicand copy
    logic [WIDTH-1:0] q [WIDTH/2-1:0]; // intermediate root (quotient)
    logic [WIDTH+1:0] ac[WIDTH/2-1:0]; // accumulator (2 bits wider)
    logic [WIDTH+1:0] test_res[WIDTH/2-1:0];     // sign test result (2 bits wider)
    genvar j;
    generate
    for (j=0;j<WIDTH/2;j=j+1) begin: sqrt_pipe
        assign test_res[j] =  ac[j] - {q[j], 2'b01};
    end  
    endgenerate 
    
    always_ff @(posedge clk) begin
        {ac[0],x[0]} <= {{WIDTH{1'b0}}, rad, 2'b0};
        q[0] <= '0;
        for (i=0; i<WIDTH/2-1; i++) begin
            if (test_res[i][WIDTH+1] == 0) begin
              {ac[i+1], x[i+1]} <= {test_res[i][WIDTH-1:0], x[i], 2'b0};
               q[i+1] <= {q[i][WIDTH-2:0], 1'b1};
            end else begin            
              {ac[i+1], x[i+1]} <= {ac[i][WIDTH-1:0], x[i], 2'b0};
              q[i+1] <= q[i] << 1;          
            end        
         end
    end 
    
    assign  root = q[WIDTH/2-1];
    assign  rem = ac[WIDTH/2-1];  
  
  
endmodule

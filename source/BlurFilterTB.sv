//*******************************************************************************************
//**
//**  File Name          : BlurFilterTB.sv
//**  Module Name        : BlurFilterTB
//**                     :
//**  Module Description : This is top level test bench which loads test image 
//**                     : and collect output from each kernel 
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
module BlurFilterTB (); 

localparam FRAME_CNT    = 1;   // # of test image 
localparam CLOCK_FREQ   = 200; // MHz
localparam CLOCK_PERIOD = (1000ns/CLOCK_FREQ);
localparam DWIDTH       = 10;

bit sys_clk;
bit sys_rst;
bit new_frame;
int frame_cnt;

logic [31:0] START_ROW;
logic [31:0] STOP_ROW;
logic [31:0] ROW_NUM;
logic [31:0] COL_NUM;
logic [31:0] PIX_PER_SLOT;
logic [31:0] LANE_N;

initial sys_clk = 1'b0;
always #(CLOCK_PERIOD/2) sys_clk = ~sys_clk;

task wait_for_reset;
  @(posedge sys_clk);
  @(posedge sys_clk);
  @(posedge sys_clk);
  sys_rst = 1'b1;
  @(posedge sys_clk);
  @(posedge sys_clk);
  @(posedge sys_clk);
  sys_rst = 1'b0;
  @(posedge sys_clk);
  @(posedge sys_clk);
  @(posedge sys_clk);
  $display("<<TESTBENCH NOTE>> system clk came out of reset");
endtask

task wait_for_new_frame;
  @(posedge sys_clk);
  new_frame = 1'b1;
  @(posedge sys_clk);
  new_frame = 1'b0;
  @(posedge sys_clk);
  @(posedge sys_clk);
  @(posedge sys_clk);
  @(posedge sys_clk);
  $display("<<TESTBENCH NOTE>> frame %0d requested", frame_cnt+1);
endtask

function int convert2Pixel (string pixel); // covert image.hex file into 10 bits pixel data
  int pixeldata;
  int pixelNibble;
  pixeldata = 0;
  for (int index =0; index < 4; index++) begin
    if (index == 2)
      continue;
    if ((pixel[index] >8'h29) & (pixel[index] < 8'h40)) begin // ASCII value to data
      pixelNibble = pixel[index] - 8'h30;
    end else
      pixelNibble = pixel[index] - 8'h37;
    case (index)
      0: pixeldata = pixeldata + (pixelNibble << 4);
      1: pixeldata = pixeldata +  pixelNibble;
      3: pixeldata = pixeldata + (pixelNibble << 8);	  
    endcase
  end
  return pixeldata;
endfunction

logic [DWIDTH-1:0]   imageData[8-1:0] ;
logic                imageDataVld;

task automatic load_image;
  int i,j,k,d,t;
  int img;
  string pixel;
  begin
    // file process
    img  = $fopen($sformatf("imgr%0d.pgm",frame_cnt+1),"w");
    $fwrite(img,"P2\n%d%d\n# CREATOR: Shen\n1023\n",COL_NUM,ROW_NUM);
    for (i = START_ROW; i < STOP_ROW; i++) begin
      // 1 clk delay between each row
      @(posedge sys_clk)
      imageDataVld = 1'b0;
      for (d = 0; d < 1; d++) begin
        @(posedge sys_clk);
      end
      for (j = 0; j < PIX_PER_SLOT; j++) begin
        @(posedge sys_clk)
        imageDataVld = (j < PIX_PER_SLOT)? 1'b1: 1'b0;
        for (k = 0; k < 8; k++) begin
          $fgets(pixel,file);
          if (j < PIX_PER_SLOT) begin
            imageData[k] = convert2Pixel(pixel);
            $fwrite(img,"%d\n",imageData[k]);
          end
        end
      end
      $display("<<TESTBENCH NOTE>> image row %d is captured!",i);
    end
    @(posedge sys_clk)
    imageDataVld = 1'b0;
    $display("<<TESTBENCH NOTE>> raw image captured!");
    $fclose(img);
  end
endtask

logic [8*DWIDTH-1:0] imageData_in;
int file;
genvar k ;
generate 
 for (k=0; k<8; k++) begin: order_swap // the process module process 8 pixel per clock, and the pixel order should be reversed.
     assign imageData_in[(7-k)*DWIDTH +: DWIDTH] = imageData[k];
 end
endgenerate

BlurFilter DUT 
(	   
     .sys_clk     (sys_clk)
    ,.sys_rst     (sys_rst) // reset associated with clk
    ,.bypass_filt ('0) // disable filter 
    ,.rowSize     (ROW_NUM)
    ,.colSize     (COL_NUM)
    ,.new_frame   (new_frame)
    ,.data_in     (imageData_in)
    ,.data_vld    (imageDataVld)  
);

task automatic capture_3x3;
int x=START_ROW; 
int y=0;
int img ;
  begin
   img = $fopen($sformatf("imgr%0d_3x3filter.pgm",frame_cnt+1),"w");
   $fwrite(img,"P2\n%d%d\n# CREATOR: Shen\n1023\n",COL_NUM,ROW_NUM);    
   @(posedge DUT.filt_3x3_vld)  
      do begin
        do begin
          @(posedge DUT.sys_clk);
           if(DUT.filt_3x3_vld ) begin
             for (int i=7; i>=0; i--)
               $fwrite(img,"%d\n",DUT.filt_3x3_data[DWIDTH*i +: DWIDTH]);             
              y=y+8;
            end
        end while (y<COL_NUM);
        y=0;
        x=x+1;
      end while (x<STOP_ROW);     
    $display("<<TESTBENCH NOTE>> 3x3 Filter succesfully captured!"); 
    $fclose(img);
  end
endtask


initial begin
  wait_for_reset();
  for (frame_cnt = 0; frame_cnt < FRAME_CNT; frame_cnt++) begin
      file = $fopen($sformatf("imgr%0d_ref_image.hex",frame_cnt+1),"r");
      if (!file)
         continue;
    START_ROW     = 0;
    STOP_ROW      = 2048;
    ROW_NUM       = STOP_ROW - START_ROW;
	 PIX_PER_SLOT  = 306;
	 LANE_N        = 8;
    COL_NUM       = PIX_PER_SLOT * LANE_N;
	 wait_for_new_frame();
	 fork
	    load_image();
		 capture_3x3();
	 join
  end
  $stop();
end   

endmodule 
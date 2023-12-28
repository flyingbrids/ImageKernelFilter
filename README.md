# ImageKernelFilter
Explore different 2D filter kernel and their implementation method in FPGA
This project requires Quartus II 15.0.2 software and its associated modelsim software
Run the .tcl file on quartus tcl console to create the project. 
After the project file is created, open the project with quartus II 15.0.2 and run compilation. After that you can run the simulation
It has one default image file (.hex) format for simulation. You can add your image file (.hex) to run the simulation. Depends on the row and column of the image, some parameter of the test bench may need to be modified accordingly. 
The maximum image column size is 2448 pixels. If need larger size, the max depth of row buffer of inferred in the filter module need to be increased accordingly.

The filters are currently organized as follows
  

         
Image --> 3x3 or 5x5 low pass (smooth) filter -> 3x3 sobel edge filter (high pass) -> gradient calculation -> 3x3 gradient non-max filter -> filtered image 
         
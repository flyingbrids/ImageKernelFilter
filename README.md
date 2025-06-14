# ImageKernelFilter
Explore different 2D filter kernel and their implementation method in FPGA
This project requires Quartus II 13.1 software and its associated modelsim software
The software can be found https://www.intel.com/content/www/us/en/software-kit/666221/intel-quartus-ii-web-edition-design-software-version-13-1-for-windows.html
Run the .tcl file on quartus tcl console to create the project. 
After the project file is created, open the project with quartus II 13.1 and run compilation. After that you can run the simulation
It has one default image file (.hex) format for simulation. You can add your image file (.hex) to run the simulation. Depends on the row and column of the image, some parameter of the test bench may need to be modified accordingly. 
The maximum image column size is 2448 pixels. If need larger size, the max depth of row buffer of inferred in the filter module need to be increased accordingly.

The filters are currently organized as follows
         
Image --> 3x3 or 5x5 low pass (smooth) filter -> 3x3 sobel edge filter (high pass) -> gradient calculation -> 3x3 gradient non-max filter -> filtered image 

Orignal Image 
![alt text](https://github.com/flyingbrids/ImageKernelFilter/blob/main/imgr1.jpg?raw=true)

Apply 3x3 low pass filter
![alt text](https://github.com/flyingbrids/ImageKernelFilter/blob/main/imgr1_3x3filter.jpg?raw=true)

Apply 5x5 low pass filter
![alt text](https://github.com/flyingbrids/ImageKernelFilter/blob/main/imgr1_5x5filter.jpg?raw=true)

Apply sobel filter and plot gradient magnitude above the set threshold
![alt text](https://github.com/flyingbrids/ImageKernelFilter/blob/main/imgr1_edgeGrad.jpg?raw=true)

Apply non-max filter after sobel 
![alt text](https://github.com/flyingbrids/ImageKernelFilter/blob/main/imgr1_nonMax.jpg?raw=true)

         
NOTE: In Quartus 13.1, to run the simulation, you will need to open Option=>EDA Tool Options, in the Modelsim_Altera executable path, add "\" at the end. 

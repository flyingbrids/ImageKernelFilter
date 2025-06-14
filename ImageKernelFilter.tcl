# Copyright (C) 1991-2013 Altera Corporation
# Your use of Altera Corporation's design tools, logic functions 
# and other software and tools, and its AMPP partner logic 
# functions, and any output files from any of the foregoing 
# (including device programming or simulation files), and any 
# associated documentation or information are expressly subject 
# to the terms and conditions of the Altera Program License 
# Subscription Agreement, Altera MegaCore Function License 
# Agreement, or other applicable license agreement, including, 
# without limitation, that your use is for the sole purpose of 
# programming logic devices manufactured by Altera and sold by 
# Altera or its authorized distributors.  Please refer to the 
# applicable agreement for further details.

# Quartus II: Generate Tcl File for Project
# File: ImageFilter.tcl
# Generated on: Thu Feb 08 20:48:22 2024

# Load Quartus II Tcl Project package
package require ::quartus::project

set need_to_close_project 0
set make_assignments 1

# Check that the right project is open
if {[is_project_open]} {
	if {[string compare $quartus(project) "ImageFilter"]} {
		puts "Project ImageFilter is not open"
		set make_assignments 0
	}
} else {
	# Only open if not already open
	if {[project_exists ImageFilter]} {
		project_open -revision ImageFilter ImageFilter
	} else {
		project_new -revision ImageFilter ImageFilter
	}
	set need_to_close_project 1
}

# Make assignments
if {$make_assignments} {
	set_global_assignment -name FAMILY "Cyclone IV E"
	set_global_assignment -name DEVICE EP4CE115F23I7
	set_global_assignment -name ORIGINAL_QUARTUS_VERSION 13.1
	set_global_assignment -name PROJECT_CREATION_TIME_DATE "16:47:41  FEBRUARY 08, 2024"
	set_global_assignment -name LAST_QUARTUS_VERSION 13.1
	set_global_assignment -name PROJECT_OUTPUT_DIRECTORY output_files
	set_global_assignment -name MIN_CORE_JUNCTION_TEMP "-40"
	set_global_assignment -name MAX_CORE_JUNCTION_TEMP 100
	set_global_assignment -name DEVICE_FILTER_PACKAGE FBGA
	set_global_assignment -name DEVICE_FILTER_PIN_COUNT 484
	set_global_assignment -name DEVICE_FILTER_SPEED_GRADE 7
	set_global_assignment -name ERROR_CHECK_FREQUENCY_DIVISOR 1
	set_global_assignment -name EDA_SIMULATION_TOOL "ModelSim-Altera (Verilog)"
	set_global_assignment -name EDA_OUTPUT_DATA_FORMAT "VERILOG HDL" -section_id eda_simulation
	set_global_assignment -name PARTITION_NETLIST_TYPE SOURCE -section_id Top
	set_global_assignment -name PARTITION_FITTER_PRESERVATION_LEVEL PLACEMENT_AND_ROUTING -section_id Top
	set_global_assignment -name PARTITION_COLOR 16764057 -section_id Top
	set_global_assignment -name POWER_PRESET_COOLING_SOLUTION "23 MM HEAT SINK WITH 200 LFPM AIRFLOW"
	set_global_assignment -name POWER_BOARD_THERMAL_MODEL "NONE (CONSERVATIVE)"
	set_global_assignment -name EDA_TIME_SCALE "1 ps" -section_id eda_simulation
	set_global_assignment -name EDA_TEST_BENCH_ENABLE_STATUS TEST_BENCH_MODE -section_id eda_simulation
	set_global_assignment -name EDA_NATIVELINK_SIMULATION_TEST_BENCH ImageFilterTB -section_id eda_simulation
	set_global_assignment -name EDA_TEST_BENCH_NAME ImageFilterTB -section_id eda_simulation
	set_global_assignment -name EDA_DESIGN_INSTANCE_NAME NA -section_id ImageFilterTB
	set_global_assignment -name EDA_TEST_BENCH_MODULE_NAME ImageFilterTB -section_id ImageFilterTB
	set_global_assignment -name EDA_TEST_BENCH_FILE source/ImageFilterTB.sv -section_id ImageFilterTB
	set_global_assignment -name HEX_FILE stimulus/imgr1_ref_image.hex
	set_global_assignment -name SDC_FILE source/timing.sdc
	set_global_assignment -name SYSTEMVERILOG_FILE source/sync_fifo.sv
	set_global_assignment -name SYSTEMVERILOG_FILE source/sqrt_pipeline.sv
	set_global_assignment -name SYSTEMVERILOG_FILE source/sobel_mask_3x3.sv
	set_global_assignment -name SYSTEMVERILOG_FILE source/sobel_3x3.sv
	set_global_assignment -name SYSTEMVERILOG_FILE source/non_max_suppression.sv
	set_global_assignment -name SYSTEMVERILOG_FILE source/nms_3x3_mask.sv
	set_global_assignment -name SYSTEMVERILOG_FILE source/line_buffer_8pix.sv
	set_global_assignment -name SYSTEMVERILOG_FILE source/ImageFilterTB.sv
	set_global_assignment -name SYSTEMVERILOG_FILE source/ImageFilter.sv
	set_global_assignment -name SYSTEMVERILOG_FILE source/gradiant.sv
	set_global_assignment -name SYSTEMVERILOG_FILE source/filter_5x5_mask.sv
	set_global_assignment -name SYSTEMVERILOG_FILE source/filter_5x5.sv
	set_global_assignment -name SYSTEMVERILOG_FILE source/filter_3x3_mask.sv
	set_global_assignment -name SYSTEMVERILOG_FILE source/filter_3x3.sv
	set_global_assignment -name QIP_FILE IP/theta_lut.qip
	set_global_assignment -name QIP_FILE IP/divide_xy.qip
	set_instance_assignment -name PARTITION_HIERARCHY root_partition -to | -section_id Top

	# Commit assignments
	export_assignments

	# Close project
	if {$need_to_close_project} {
		project_close
	}
}

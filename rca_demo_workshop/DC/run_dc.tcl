# Set the library path
set PDK_PATH	 "/home/SCL_PDK/SCLPDK_V3.0_KIT/scl180"  

# Name of the top-level design
set DESIGN_NAME  "RCA"

# Setting up of Synopsys environment
source -echo -verbose ./rm_setup/dc_setup.tcl

# Define RTL files
set RTL_SOURCE_FILES " ./../rtl/FA.v ./../rtl/RCA.v ./../rtl/register.v "

define_design_lib WORK -path ./WORK

#set_dont_use [get_lib_cells */an*]

# Elaborate design
analyze -format verilog ${RTL_SOURCE_FILES}
elaborate ${DESIGN_NAME}
current_design

# Read constraint file
read_sdc  -echo ./../CONSTRAINTS/rca.sdc

# Perform synthesis
compile
#compile_ultra

# Generate reports 
report_timing > ./${REPORTS_DIR}/${DCRM_FINAL_TIMING_REPORT}
report_power  > ./${REPORTS_DIR}/${DCRM_FINAL_POWER_REPORT}
report_area   > ./${REPORTS_DIR}/${DCRM_FINAL_AREA_REPORT}

# Write mapped gate level netlist
write -format verilog -hierarchy -output ${RESULTS_DIR}/${DCRM_FINAL_VERILOG_OUTPUT_FILE}

# Write the files needed to load the design in IC compiler II
write_sdc ./${RESULTS_DIR}/${DCRM_FINAL_SDC_OUTPUT_FILE}
write_icc2_files -output icc2_files -force
write_sdf ./${RESULTS_DIR}/${DCRM_FINAL_SDF_OUTPUT_FILE}



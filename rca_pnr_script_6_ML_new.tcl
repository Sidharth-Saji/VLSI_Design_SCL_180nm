# Inside your rca design folder
# create ICC2 and PT
mkdir ICC2 PT

# go inside the ICC2 folder
cd ICC2

# Inside the ICC2 folder create folders { reports results logs library_manager inputs scripts }
mkdir reports results logs library_manager inputs scripts

# copy your netlist file and output constrints file into the inputs directory present inside ICC2 folder
cp -rf ../DC/results/RCA.mapped.v ./inputs/
cp -rf ../DC/results/RCA.mapped.sdc ./inputs/

# go inside the library_manager folder
cd library_manager

# source the licence file
csh
source /home/synopsys/cshrc

# open the library manager tool
lm_shell


################################### step:1 creating the .ndm database ###################################

start_gui

## Reading technology file
create_workspace -flow exploration -technology /home/SCL_PDK/SCLPDK_V3.0_KIT/scl180/digital_pnr_kit/snps/non_rh/6M1L/SCL_6LM.tf ExplorationWorkspace

## Reading Logical library (.db) file
read_db { /home/SCL_PDK/SCLPDK_V3.0_KIT/scl180/stdcell/fs120/6M1L/liberty/lib_flow_ss/tsl18fs120_scl_ss.db /home/SCL_PDK/SCLPDK_V3.0_KIT/scl180/stdcell/fs120/6M1L/liberty/lib_flow_ff/tsl18fs120_scl_ff.db}

## Reading physical library (.lef) file
read_lef /home/SCL_PDK/SCLPDK_V3.0_KIT/scl180/stdcell/fs120/6M1L/lef/scl18fs120_tech.lef
read_lef /home/SCL_PDK/SCLPDK_V3.0_KIT/scl180/stdcell/fs120/6M1L/lef/scl18fs120_std.lef

## Reading Graphical Data stream (.gds) file
read_gds /home/SCL_PDK/SCLPDK_V3.0_KIT/scl180/stdcell/fs120/6M1L/gds/scl18fs120.gds

group_libs

check_workspace

## compiles all the files and creates .ndm files 
process_workspaces

exit
#################################################
cd ..
# icc2_shell -list_all
icc2_shell -output_log_file ./logs/filename.log -gui

####################################### step:2 Floorplan #####################################

set PDK_PATH ./library_manager

#create a new design library for your design with some name <RCA_6mtl_LIB>
create_lib -ref_lib $PDK_PATH/tsl18fs120_scl.ndm RCA_6mtl_LIB

#read the mapped netlist and pass the library 
read_verilog {./inputs/RCA.mapped.v} -library RCA_6mtl_LIB

# sanity check
check_design -checks {dp_pre_floorplan}

#initialize_floorplan will defaultly generate a square floor plan this will generate core utilization area also

initialize_floorplan -core_utilization 0.40 -core_offset {4 4} -coincident_boundary true -flip_first_row true


#initialize_floorplan -shape T \
                 #-side_length {1000 750 2500 500 3000 500} \
                 #-core_offset {100 100 100 100 100 100 100 100}

# Tool will automatically place the pins
place_pins -self

create_placement -floorplan

save_block -as floorplan_done

save_lib

############################################################
# Optional commands to close and open saved design
############################################################

close_blocks

close_lib

#open_lib < YOUR LIB NAME >
open_lib RCA_6mtl_LIB

# list out all the blocks
list_blocks

#open_block < YOUR BLOCK NAME >
open_block floorplan_done

######################################## Step:3 powerplan #####################################

check_design -checks legality

# To create power net
create_net -power {VDD}
create_net -ground {VSS}

# To automatically connect powernets to all the blocks
connect_pg_net -all_blocks -automatic

# To create the core power ring
# get_attribute [get_layers {M1 M2 M3 M4 M5 TOP_M}] routing_direction
create_pg_ring_pattern core_ring_pattern -horizontal_layer M5 -horizontal_width .4 -horizontal_spacing .5 -vertical_layer TOP_M -vertical_width .5 -vertical_spacing .5

set_pg_strategy core_power_ring -core -pattern {{name : core_ring_pattern}{nets : {VDD VSS}}{offset : {.5 1}}}

#offset : {.5 1}Distance from core boundary to place the rings:.5µm for one layer direction, 1µm for the other (usually horizontal vs vertical offset)

compile_pg -strategies core_power_ring

# To create pg mesh pattern
create_pg_mesh_pattern mesh -layers { {{vertical_layer: M4}{width: 1} {spacing: interleaving}{pitch: 22.4} {offset: .5}} {{horizontal_layer: M5}{width: 1} {spacing: interleaving} {pitch: 22.4} {offset: .5}} }

set_pg_strategy core_mesh -pattern { {pattern:mesh} {nets: VDD VSS}} -core -extension {stop: innermost_ring}

compile_pg -strategies core_mesh

# To create std cell power rail pattern
create_pg_std_cell_conn_pattern std_cell_rail -layers {M1} -rail_width 0.06

set_pg_strategy rail_strat -core -pattern {{name: std_cell_rail} {nets: VDD VSS} }

compile_pg -strategies rail_strat

save_block -as powerplan_done
save_lib
close_blocks
close_lib
open_lib RCA_6mtl_LIB
open_block powerplan_done

############################################### step:4 Placement #####################################

check_design -checks pre_placement_stage

remove_modes -all
remove_corners -all
remove_scenarios -all

#set mode  and corner
set mode1 "func"
set corner1 "nom"
set scenario1 "${mode1}::${corner1}"

#create mode and corner

create_mode $mode1
create_corner $corner1
create_scenario -name func::nom -mode func -corner nom

# source the constraints
source ./inputs/RCA.mapped.sdc


set parasitic1 "p1"
set tluplus_file$parasitic1 "/home/SCL_PDK/SCLPDK_V3.0_KIT/scl180/digital_pnr_kit/snps/non_rh/6M1L/SCL_TLUPLUS_6M1L_TYP.tlup"
set layer_map_file$parasitic1 "/home/SCL_PDK/SCLPDK_V3.0_KIT/scl180/digital_pnr_kit/snps/non_rh/6M1L/SCL_TLUPLUS_6M1L.map"

read_parasitic_tech -tlup $tluplus_filep1 -layermap $layer_map_filep1 -name p1

set_parasitic_parameters -late_spec $parasitic1 -early_spec $parasitic1



# to set missing scandef
set_app_options -name place.coarse.continue_on_missing_scandef -value true

#to place  pins and initialize placement
place_pins -self

create_placement

legalize_placement

place_opt -list_only
# place_opt

## Check for utilization
report_utilization

# check for report_timing now

report_timing > ./results/placement_timing.rpt

save_block -as placement_done
save_lib
close_blocks
close_lib
open_lib RCA_6mtl_LIB
open_block placement_done


###################################### step:5 Clock Tree Synthesis ####################

check_design -checks pre_clock_tree_stage
synthesize_clock_tree

set_app_options -name cts.optimize.enable_local_skew -value true
set_app_options -name cts.compile.enable_local_skew -value true
set_app_options -name cts.compile.enable_global_route -value false
set_app_options -name clock_opt.flow.enable_ccd -value true

clock_opt -to build_clock

clock_opt -from route_clock -to route_clock
clock_opt

## Check for utilization
report_utilization

save_block -as cts_done
save_lib
close_blocks
close_lib
open_lib RCA_6mtl_LIB
open_block cts_done




###################### step6: Routing #################

# pre checks
check_design -checks pre_route_stage

#global route
set_app_options -name route.global.timing_driven -value true
set_app_options -name route.global.crosstalk_driven -value false

#track assignment
set_app_options -name route.track.timing_driven -value true
set_app_options -name route.track.crosstalk_driven -value true

#detail route
set_app_options -name route.detail.timing_driven -value true
set_app_options -name route.detail.force_max_number_iterations -value false

#route_global
#route_track
#route_detail

#(same as route_global+ route_track+ route_detail)
route_opt

## Check for utilization
report_utilization

save_block -as routing_done
save_lib

# generating outputs

write_verilog ./results/RCA_6mtl.routed.v
write_sdc -output ./results/RCA_6mtl.routed.sdc
write_parasitics -format spef -output ./results/RCA_6mtl.spef
write_def ./results/RCA_6mtl.def
# man write_gds 

################################## STA #################################
## check for setup voilation
report_timing -delay_type max

## check for hold voilation
report_timing -delay_type min

## man report_timing
 
exit

#############################################################



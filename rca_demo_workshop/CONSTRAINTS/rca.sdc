create_clock -period 5 [get_ports clk]

#set_input_delay -max 0.25 -clock clk [all_inputs]
#set_input_transition 0.2 [all_inputs]

#set_output_delay -max 0.25 -clock clk [all_outputs]

#set_clock_uncertainty -setup 0.100 [get_clocks clk]
#set_clock_uncertainty -hold 0.100 [get_clocks clk]
#set_max_transition 0.20 [current_design]
#set_max_transition -clock_path 0.150 [get_clocks clk]

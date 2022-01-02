# TCL File Generated by Component Editor 18.1
# Sun Jan 02 16:45:55 CET 2022
# DO NOT MODIFY


# 
# camera_controller "camera_controller" v2.0
# Taras Pavliv, Martin Simik 2022.01.02.16:45:55
# 
# 

# 
# request TCL package from ACDS 16.1
# 
package require -exact qsys 16.1


# 
# module camera_controller
# 
set_module_property DESCRIPTION ""
set_module_property NAME camera_controller
set_module_property VERSION 2.0
set_module_property INTERNAL false
set_module_property OPAQUE_ADDRESS_MAP true
set_module_property GROUP custom_PIs
set_module_property AUTHOR "Taras Pavliv, Martin Simik"
set_module_property DISPLAY_NAME camera_controller
set_module_property INSTANTIATE_IN_SYSTEM_MODULE true
set_module_property EDITABLE true
set_module_property REPORT_TO_TALKBACK false
set_module_property ALLOW_GREYBOX_GENERATION false
set_module_property REPORT_HIERARCHY false


# 
# file sets
# 
add_fileset QUARTUS_SYNTH QUARTUS_SYNTH "" ""
set_fileset_property QUARTUS_SYNTH TOP_LEVEL D5M_CONTROLLER_LINKER
set_fileset_property QUARTUS_SYNTH ENABLE_RELATIVE_INCLUDE_PATHS false
set_fileset_property QUARTUS_SYNTH ENABLE_FILE_OVERWRITE_MODE false
add_fileset_file AVALON_MASTER.vhd VHDL PATH ../hdl/AVALON_MASTER.vhd
add_fileset_file AVALON_SLAVE.vhd VHDL PATH ../hdl/AVALON_SLAVE.vhd
add_fileset_file Bayer_FIFO.vhd VHDL PATH ../hdl/Bayer_FIFO.vhd
add_fileset_file Buffer_FIFO.vhd VHDL PATH ../hdl/Buffer_FIFO.vhd
add_fileset_file D5M_CONTROLLER_LINKER.vhd VHDL PATH ../hdl/D5M_CONTROLLER_LINKER.vhd TOP_LEVEL_FILE
add_fileset_file D5M_CTRL.vhd VHDL PATH ../hdl/D5M_CTRL.vhd


# 
# parameters
# 


# 
# display items
# 


# 
# connection point clock
# 
add_interface clock clock end
set_interface_property clock clockRate 0
set_interface_property clock ENABLED true
set_interface_property clock EXPORT_OF ""
set_interface_property clock PORT_NAME_MAP ""
set_interface_property clock CMSIS_SVD_VARIABLES ""
set_interface_property clock SVD_ADDRESS_GROUP ""

add_interface_port clock csi_clk clk Input 1


# 
# connection point reset
# 
add_interface reset reset end
set_interface_property reset associatedClock clock
set_interface_property reset synchronousEdges DEASSERT
set_interface_property reset ENABLED true
set_interface_property reset EXPORT_OF ""
set_interface_property reset PORT_NAME_MAP ""
set_interface_property reset CMSIS_SVD_VARIABLES ""
set_interface_property reset SVD_ADDRESS_GROUP ""

add_interface_port reset rsi_reset_n reset_n Input 1


# 
# connection point s0
# 
add_interface s0 avalon end
set_interface_property s0 addressUnits WORDS
set_interface_property s0 associatedClock clock
set_interface_property s0 associatedReset reset
set_interface_property s0 bitsPerSymbol 8
set_interface_property s0 burstOnBurstBoundariesOnly false
set_interface_property s0 burstcountUnits WORDS
set_interface_property s0 explicitAddressSpan 0
set_interface_property s0 holdTime 0
set_interface_property s0 linewrapBursts false
set_interface_property s0 maximumPendingReadTransactions 0
set_interface_property s0 maximumPendingWriteTransactions 0
set_interface_property s0 readLatency 0
set_interface_property s0 readWaitTime 1
set_interface_property s0 setupTime 0
set_interface_property s0 timingUnits Cycles
set_interface_property s0 writeWaitTime 0
set_interface_property s0 ENABLED true
set_interface_property s0 EXPORT_OF ""
set_interface_property s0 PORT_NAME_MAP ""
set_interface_property s0 CMSIS_SVD_VARIABLES ""
set_interface_property s0 SVD_ADDRESS_GROUP ""

add_interface_port s0 avs_s0_address address Input 4
add_interface_port s0 avs_s0_write write Input 1
add_interface_port s0 avs_s0_read read Input 1
add_interface_port s0 avs_s0_writedata writedata Input 32
add_interface_port s0 avs_s0_readdata readdata Output 32
set_interface_assignment s0 embeddedsw.configuration.isFlash 0
set_interface_assignment s0 embeddedsw.configuration.isMemoryDevice 0
set_interface_assignment s0 embeddedsw.configuration.isNonVolatileStorage 0
set_interface_assignment s0 embeddedsw.configuration.isPrintableDevice 0


# 
# connection point m0_1
# 
add_interface m0_1 avalon start
set_interface_property m0_1 addressUnits SYMBOLS
set_interface_property m0_1 associatedClock clock
set_interface_property m0_1 associatedReset reset
set_interface_property m0_1 bitsPerSymbol 8
set_interface_property m0_1 burstOnBurstBoundariesOnly false
set_interface_property m0_1 burstcountUnits WORDS
set_interface_property m0_1 doStreamReads false
set_interface_property m0_1 doStreamWrites false
set_interface_property m0_1 holdTime 0
set_interface_property m0_1 linewrapBursts false
set_interface_property m0_1 maximumPendingReadTransactions 0
set_interface_property m0_1 maximumPendingWriteTransactions 0
set_interface_property m0_1 readLatency 0
set_interface_property m0_1 readWaitTime 1
set_interface_property m0_1 setupTime 0
set_interface_property m0_1 timingUnits Cycles
set_interface_property m0_1 writeWaitTime 0
set_interface_property m0_1 ENABLED true
set_interface_property m0_1 EXPORT_OF ""
set_interface_property m0_1 PORT_NAME_MAP ""
set_interface_property m0_1 CMSIS_SVD_VARIABLES ""
set_interface_property m0_1 SVD_ADDRESS_GROUP ""

add_interface_port m0_1 avm_m0_address address Output 32
add_interface_port m0_1 avm_m0_writedata writedata Output 32
add_interface_port m0_1 avm_m0_write write Output 1
add_interface_port m0_1 avm_m0_waitrequest waitrequest Input 1
add_interface_port m0_1 avm_m0_byteenable byteenable Output 4


# 
# connection point conduit_end
# 
add_interface conduit_end conduit end
set_interface_property conduit_end associatedClock clock
set_interface_property conduit_end associatedReset ""
set_interface_property conduit_end ENABLED true
set_interface_property conduit_end EXPORT_OF ""
set_interface_property conduit_end PORT_NAME_MAP ""
set_interface_property conduit_end CMSIS_SVD_VARIABLES ""
set_interface_property conduit_end SVD_ADDRESS_GROUP ""

add_interface_port conduit_end GPIO_1_D5M_D data Input 12
add_interface_port conduit_end GPIO_1_D5M_FVAL fval Input 1
add_interface_port conduit_end GPIO_1_D5M_LVAL lval Input 1
add_interface_port conduit_end GPIO_1_D5M_PIXCLK pxclk Input 1
add_interface_port conduit_end GPIO_1_D5M_RESET_N reset Output 1
add_interface_port conduit_end GPIO_1_D5M_XCLKIN xclkin Output 1


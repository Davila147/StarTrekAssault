ghdl -a StarTrekAssault_completo.vhd
ghdl -a StarTrekAssault_tb.vhd
ghdl -e testbench
ghdl -r testbench --vcd=result.vcd

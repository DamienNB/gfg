#test_gfg_frame_buffers_controller_and_datapath_simple:
#	iverilog -o gfg_frame_buffers_controller_and_datapath_simple_tb.o gfg_frame_buffers_controller_and_datapath_simple_tb.v gfg_frame_buffers_controller_and_datapath_simple.v ram_dual_port.v
#	vvp gfg_frame_buffers_controller_and_datapath_simple_tb.o -lxt2
#	gtkwave gfg_frame_buffers_controller_and_datapath_simple_tb.lxt > /dev/null 2>&1 &

#test_gfg_round_robin_reservation_arbiter:
#	iverilog -o gfg_round_robin_reservation_arbiter_tb.o gfg_round_robin_reservation_arbiter_tb.v gfg_round_robin_reservation_arbiter.v ram_dual_port.v
#	vvp gfg_round_robin_reservation_arbiter_tb.o -lxt2
#	gtkwave gfg_round_robin_reservation_arbiter_tb.lxt > /dev/null 2>&1 &

test_rasterizer_triangle_intersection_detector:
	cd testbench && \
	iverilog -o ./rasterizer_triangle_intersection_detector_tb.o ./rasterizer_triangle_intersection_detector_tb.v ../rtl/rasterizer_triangle_intersection_detector.v && \
	vvp ./rasterizer_triangle_intersection_detector_tb.o -lxt2 && \
	gtkwave ./rasterizer_triangle_intersection_detector_tb.lxt > /dev/null 2>&1 &

test_rasterizer:
	cd testbench && \
	iverilog -o ./rasterizer_tb.o ./rasterizer_tb.v ../rtl/rasterizer.v ../rtl/rasterizer_triangle_intersection_detector.v && \
	vvp ./rasterizer_tb.o -lxt2 && \
	gtkwave ./rasterizer_tb.lxt > /dev/null 2>&1 &

test_frame_buffers_swapping_controller:
	cd testbench && \
	iverilog -o ./frame_buffers_swapping_controller_tb.o ./frame_buffers_swapping_controller_tb.v ../rtl/frame_buffers_swapping_controller.v && \
	vvp ./frame_buffers_swapping_controller_tb.o -lxt2 && \
	gtkwave ./frame_buffers_swapping_controller_tb.lxt > /dev/null 2>&1 &

test_vga_output:
	cd testbench && \
	iverilog -o ./vga_output_tb.o ./vga_output_tb.v ../rtl/vga_output.v && \
	vvp ./vga_output_tb.o -lxt2 && \
	gtkwave ./vga_output_tb.lxt > /dev/null 2>&1 &

clean:
	cd testbench && \
	rm -f *.o *.vcd *.lxt

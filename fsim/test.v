`timescale 1ns/100ps

module test
(
    clk,
    rst_l,
    tst,
    clk1ms	//1 millisecond clock
);


input clk;
input rst_l;
output clk1ms;	//1 millisecond clock
input [7:0] tst;

reg [15:0] q;
reg clk1ms_r;

// Counter

always @(posedge clk or negedge rst_l)
	begin
		if (rst_l == 0)
		begin 
			q <= 0;
			clk1ms_r <= 1'b0;
		end
		else
		begin	
			if (q == 16'h3333) //0x2710 = 1ms
		    begin
				clk1ms_r <= !clk1ms_r;
				q <= 1'b0;
			end
			else
			begin
				q <= q + 16'h0001;
			end
		end
	end
	
	assign clk1ms		=		clk1ms_r;

//`ifdef COCOTB_SIM
initial begin
  $dumpfile ("waveform.vcd");
  $dumpvars (0,test);  
  #1;
end
//`endif
endmodule

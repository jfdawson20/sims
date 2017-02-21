`timescale 1ns/100ps

module rmii_loop
(   
    refclk, 
    rst_l,
    
    txd,
    tx_en,

    rx_er,
    crs_dv,
    rxd
);

input refclk; 
input rst_l;
    
input [1:0] txd;
input tx_en;

output rx_er;
output crs_dv;
output [1:0] rxd;

reg [1:0] data_r;
reg crs_dv_r; 

always @ (posedge(refclk)) begin 
    if(rst_l == 1'b0) begin 
        data_r   = 2'b0; 
        crs_dv_r = 1'b0;
    end

    else if(refclk == 1'b1) begin 
        data_r = txd;
        crs_dv_r = tx_en;
    end
end

assign rxd[1]    = data_r[1]; 
assign rxd[0]    = data_r[0]; 
assign crs_dv = crs_dv_r;
assign rx_er  = 1'b0;

//`ifdef COCOTB_SIM 
initial begin 
  $dumpfile ("waveform.vcd"); 
  $dumpvars (0,rmii_loop);   
  #1; 
end 
//`endif 

endmodule

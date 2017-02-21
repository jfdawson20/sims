`timescale 1ps/1ps

module rmii_mii(
    //rmii
    rmii_refclk,
    rst_l,

    rmii_txd,
    rmii_tx_en,

    rmii_rx_er,
    rmii_crs_dv,
    rmii_rxd,

    //mii
    mii_rxclk,
    mii_rxd,
    mii_rx_dv,
    mii_rx_er,
    mii_crs,
    mii_col,

    mii_txclk,
    mii_txd,
    mii_tx_en,
    mii_tx_er

);

//rmii interface
input rmii_refclk;
input rst_l;

input [1:0] rmii_txd;
input rmii_tx_en;

output rmii_rx_er;
output rmii_crs_dv;
output [1:0] rmii_rxd;

//mii interface
input mii_rxclk;
input [3:0] mii_rxd;
input mii_rx_dv;
input mii_rx_er;
input mii_crs;
input mii_col;

input mii_txclk;
output [3:0] mii_txd;
output mii_tx_en;
output mii_tx_er;


//internal signals
reg [3:0] mii_data_rx_r1;
reg [3:0] mii_data_rx_r2;
reg [1:0] rmii_data_rx_r1;
reg nib;

reg mii_crs_r1;
reg mii_crs_r2;
reg mii_rx_dv_r1;
reg mii_rx_dv_r2;
reg rmii_crs_dv_r1;

reg mii_rx_er_r1;
reg mii_rx_er_r2;
reg rmii_rx_er_r1;


reg [3:0] mii_data_tx_r1;
reg [3:0] mii_data_tx_r2;
reg [3:0] mii_data_tx_r3;
reg mii_tx_en_r1;
reg mii_tx_en_r2;
reg mii_tx_en_r3;

reg mii_clk_rx_r;
reg crs_dv_r;

// -------------------------- RMII/MII Transmit Path --------------------- \\
//rmii to mii (tx)
always @ (posedge(rmii_refclk)) begin
    if(rst_l == 1'b0) begin
        mii_data_tx_r1 = 4'b0000;
        mii_tx_en_r1   = 1'b0;
    end

    else if(rmii_refclk == 1'b1) begin
        mii_data_tx_r1[3:2] = mii_data_tx_r1[1:0];
        mii_data_tx_r1[1:0] = rmii_txd;
        mii_tx_en_r1 = rmii_tx_en;
    end
end

//sync mii to mii tx_clk domain
always @ (posedge(mii_txclk)) begin
    if(rst_l == 1'b0) begin
        mii_data_tx_r2 = 4'b0000;
        mii_data_tx_r3 = 4'b0000;

        mii_tx_en_r2   = 1'b0;
        mii_tx_en_r3   = 1'b0;
    end

    if(mii_txclk == 1'b1) begin
        mii_data_tx_r2 = mii_data_tx_r1;
        mii_data_tx_r3 = mii_data_tx_r2;

        mii_tx_en_r2   = mii_tx_en_r1;
        mii_tx_en_r3   = mii_tx_en_r2;
    end

end

assign mii_txd   = mii_data_tx_r3;
assign mii_tx_en = mii_tx_en_r3;

// -------------------------- RMII/MII Receive Path --------------------- \\
//sync mii rx signals to rmii rx clock domain
always @ (posedge(rmii_refclk)) begin
    if(rst_l == 1'b0) begin
        mii_data_rx_r1 = 4'b0000;
        mii_data_rx_r2 = 4'b0000;
        mii_crs_r1 = 1'b0;
        mii_crs_r2 = 1'b0;

        mii_rx_dv_r1 = 1'b0;
        mii_rx_dv_r2 = 1'b0;

        mii_rx_er_r1 = 1'b0;
        mii_rx_er_r2 = 1'b0;
    end

    else if (rmii_refclk == 1'b1) begin
        mii_data_rx_r1 = mii_rxd;
        mii_data_rx_r2 = mii_data_rx_r1;

        mii_crs_r1 = mii_crs;
        mii_crs_r2 = mii_crs_r1;

        mii_rx_dv_r1 = mii_rx_dv;
        mii_rx_dv_r2 = mii_rx_dv_r1;

        mii_rx_er_r1 = mii_rx_er;
        mii_rx_er_r2 = mii_rx_er_r1;
    end
end

//convert synced mii data to rmii data
always @ (posedge(rmii_refclk)) begin
    if(rst_l == 1'b0) begin
        rmii_data_rx_r1 = 2'b00;
        rmii_crs_dv_r1 = 1'b0;
        rmii_rx_er_r1  = 1'b0;
        nib = 1'b0;
    end
    else if (rmii_refclk == 1'b1) begin
        if(nib == 1'b0) begin
            rmii_data_rx_r1[1:0] = mii_data_rx_r2[1:0];
            nib = 1;
        end
        else begin
            rmii_data_rx_r1[1:0] = mii_data_rx_r2[3:2];
            nib = 0;
        end
        rmii_crs_dv_r1 = (mii_crs_r2 | mii_rx_dv_r2);
        rmii_rx_er_r1  = mii_rx_er_r2;
    end
end

assign rmii_rxd    = rmii_data_rx_r1;
assign rmii_crs_dv = rmii_crs_dv_r1;
assign rmii_rx_er  = rmii_rx_er_r1;

endmodule


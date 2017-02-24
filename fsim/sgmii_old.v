module mii_sgmii (
    //module reset
    rst_l, 
    
    //sgmii rx/tx
    tx,
    rx, 

    //mii interface 
    mii_rxclk, 
    mii_rxd, 
    mii_rx_dv, 
    mii_rx_er, 
    mii_rx_crs, 
    mii_rx_col,

    mii_txclk, 
    mii_txd,
    mii_tx_en, 
    mii_tx_er
    );

    //module reset
input rst_l; 
    
    //sgmii rx/tx
output tx;
input rx; 

    //mii interface 
input mii_rxclk; 
output [3:0] mii_rxd; 
output mii_rx_dv; 
output mii_rx_er; 
output mii_rx_crs; 
output mii_rx_col;

input mii_txclk; 
input [3:0] mii_txd;
input mii_tx_en; 
input mii_tx_er;

//interal regs and wires
wire [8:0] DataFromEnc; 
reg  [8:0] DataFromEnc_r; 
reg  [8:0] DataToEnc_r; 
reg  [8:0] DataToEnc_r1; 
reg enc_clk; 

wire [9:0] EncodedDataIn;
wire [9:0] EncodedDataOut;
reg  [9:0] EncodedDataOut_r;

//generate clock running half the frequency of mii clock 
//shift mii data into 8 bit reg 
always @ (posedge(mii_txclk),rst_l) begin 
    if(rst_l == 1'b0) begin 
        enc_clk     <= 1'b0;
        DataToEnc_r <= 9'b000000000; 
    end
    else if(mii_txclk == 1'b1) begin 
        enc_clk = !enc_clk; 
        DataToEnc_r[8]   <= 1'b0;
        DataToEnc_r[3:0] <= DataToEnc_r[7:4]; 
        DataToEnc_r[7:4] <= mii_txd;
    end
end 

always @ (posedge(mii_txclk)) begin 
    if(rst_l == 1'b0) begin 
        DataToEnc_r1 = 9'b000000000;
    end
    else if (mii_txclk == 1'b1) begin 
        DataToEnc_r1 <= DataToEnc_r;
    end

end

//8b10b encode and decode modules
wire Encode_disp;
reg  Encode_disp_r;
encode encode_8b10b 
(
    .datain(DataToEnc_r1), 
    .dispin(Encode_disp_r),
    .dataout(EncodedDataOut), 
    .dispout(Encode_disp)
);

//register output of encoded data 
always @ (posedge(enc_clk),rst_l) begin 
    if(rst_l == 1'b0) begin 
        EncodedDataOut_r <= 10'b0000000000;
        Encode_disp_r    <= 1'b0; 
    end
    else if (enc_clk == 1'b1) begin 
        EncodedDataOut_r <= EncodedDataOut; 
        Encode_disp_r    <= Encode_disp; 
    end
end

wire Decode_disp;
reg  Decode_disp_r;
reg  code_err_r;
wire code_err;
reg  disp_err_r; 
wire disp_err; 

decode decode_8b10b 
(
    .datain(EncodedDataIn),
    .dispin(Decode_disp_r),
    .dataout(DataFromEnc),
    .dispout(Decode_disp), 
    .code_err(code_err),
    .disp_err(disp_err)
);

always @ (posedge(enc_clk),rst_l,mii_tx_en) begin 
    if(rst_l == 1'b0 | mii_tx_en == 1'b0) begin 
        DataFromEnc_r <= 9'b000000000;
        Decode_disp_r <= 1'b0;
        code_err_r    <= 1'b0;
        disp_err_r    <= 1'b0;
    end
    else if (enc_clk == 1'b1) begin 
        DataFromEnc_r <= DataFromEnc; 
        Decode_disp_r <= Decode_disp; 
        code_err_r    <= code_err; 
        disp_err_r    <= disp_err; 
    end
end

assign EncodedDataIn = EncodedDataOut_r; 

//preamble/sfd detect pipeline
reg [8:0] data_out_pipe [0:2];
reg match_0; 
reg match_1; 
reg match_2; 

always @ (posedge(enc_clk),rst_l) begin 
    if(rst_l == 1'b0) begin 
        match_0 = 1'b0;
        match_1 = 1'b0; 
        match_2 = 1'b0;
        data_out_pipe[0] <= 9'b00000000;
        data_out_pipe[1] <= 9'b00000000;
        data_out_pipe[2] <= 9'b00000000;
        //data_out_pipe[3] = 8'b00000000;
        //data_out_pipe[4] = 8'b00000000;
        //data_out_pipe[5] = 8'b00000000;
        //data_out_pipe[6] = 8'b00000000;
        //data_out_pipe[7] = 8'b00000000;
    end
    else if(enc_clk == 1'b1) begin 
        data_out_pipe[0] <= DataFromEnc_r;
        data_out_pipe[1] <= data_out_pipe[0];
        data_out_pipe[2] <= data_out_pipe[1];
        //data_out_pipe[3] = data_out_pipe[2];
        //data_out_pipe[4] = data_out_pipe[3];
        //data_out_pipe[5] = data_out_pipe[4];
        //data_out_pipe[6] = data_out_pipe[5];
        //data_out_pipe[7] = data_out_pipe[6];
    end

    if(data_out_pipe[0][7:0] == 8'hd5) begin 
        match_0 <= 1'b1;
    end
    else if (data_out_pipe[0][7:0] == 8'b00000000) begin 
        match_0 <= 1'b0; 
    end

    if(data_out_pipe[1][7:0] == 8'h55) begin 
        match_1 <= 1'b1; 
    end
    else if (data_out_pipe[1][7:0] == 8'b00000000) begin 
        match_1 <= 1'b0; 
    end
    if(data_out_pipe[2][7:0] == 8'h55) begin 
        match_2 <= 1'b1;
    end
    else if (data_out_pipe[2][7:0] == 8'b00000000) begin 
        match_2 <= 1'b0; 
    end
end

wire sof;

assign sof = (match_0 & match_1 & match_2);
assign eof = (!match_0 & !match_1 & !match_2);

//convert decoded 8 bit data to mii data
reg nib;
reg [3:0] mii_out; 
always @ (posedge(mii_txclk),rst_l) begin 
    if(rst_l == 1'b0 | mii_tx_en == 1'b0 ) begin 
        nib     <= 1'b0;
        mii_out <= 4'b0000; 
    end
    else if (mii_txclk == 1'b1) begin 
        if(nib == 1'b0) begin
            mii_out <= data_out_pipe[2][7:4];
            nib     <= 1'b1; 
        end
        else begin 
            mii_out <= data_out_pipe[2][3:0];
            nib     <= 1'b0;
        end
    end 
end


reg mii_rx_dv_r;
reg mii_rx_crs_r;
always @ (sof,eof) begin 
    if(rst_l == 1'b0) begin 
        mii_rx_dv_r  = 1'b0;
        mii_rx_crs_r = 1'b0;
    end
    else begin 
        if(sof == 1'b1) begin 
            mii_rx_dv_r  = 1'b1; 
            mii_rx_crs_r = 1'b1; 
        end
        else if(eof == 1'b1) begin 
            mii_rx_dv_r  = 1'b0;
            mii_rx_crs_r = 1'b0; 
        end
    end
end


assign mii_rxd    = mii_out; 
assign mii_rx_dv  = mii_rx_dv_r;
assign mii_rx_crs = mii_rx_crs_r;
assign mii_rx_er  = 1'b0;
assign mii_rx_col = 1'b0;


//`ifdef COCOTB_SIM 
initial begin
  $dumpfile ("waveform.vcd");
  $dumpvars (0,data_out_pipe[0],data_out_pipe[1],data_out_pipe[2]);
  #1;
end
//`endif

/*
assign mii_rx_dv  = mii_tx_en; 
assign mii_rx_crs = mii_tx_en;

assign mii_rxd = mii_txd; 

assign mii_rx_er = 1'b0; 
assign mii_rx_col = 1'b0;
*/



endmodule 

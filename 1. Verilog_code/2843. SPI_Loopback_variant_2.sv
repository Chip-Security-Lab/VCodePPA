//SystemVerilog
//IEEE 1364-2005 Verilog
module SPI_Loopback #(
    parameter PRBS_SEED = 32'h12345678
)(
    input clk,
    input rst,
    input loopback_en,
    input external_loop,
    output reg error_flag,
    output [7:0] error_count,
    // SPI接口
    output sclk,
    output cs_n,
    inout mosi,
    inout miso
);

// ==========================
// Stage 1: SPI Clock, CS, PRBS Seed
// ==========================
reg sclk_stage1;
reg cs_n_stage1;
reg [31:0] prbs_reg_stage1;
reg valid_stage1;
reg flush_stage1;

always @(posedge clk or posedge rst) begin
    if (rst) begin
        sclk_stage1     <= 1'b0;
        cs_n_stage1     <= 1'b1;
        prbs_reg_stage1 <= PRBS_SEED;
        valid_stage1    <= 1'b0;
        flush_stage1    <= 1'b1;
    end else begin
        sclk_stage1     <= ~sclk_stage1;
        cs_n_stage1     <= loopback_en ? 1'b0 : 1'b1;
        valid_stage1    <= loopback_en;
        flush_stage1    <= ~loopback_en;
        if (loopback_en && !cs_n_stage1)
            prbs_reg_stage1 <= {prbs_reg_stage1[30:0], prbs_reg_stage1[3] ^ prbs_reg_stage1[5]};
        else
            prbs_reg_stage1 <= PRBS_SEED;
    end
end

wire prbs_bit_stage1 = prbs_reg_stage1[0];

// ==========================
// Stage 2: PRBS, TX/RX pipeline, Bit Counter
// ==========================
reg sclk_stage2;
reg cs_n_stage2;
reg [31:0] prbs_reg_stage2;
reg [7:0] tx_data_stage2;
reg [7:0] rx_data_stage2;
reg [3:0] bit_cnt_stage2;
reg mosi_o_stage2, miso_o_stage2;
reg valid_stage2;
reg flush_stage2;

// Input Buffers
wire mosi_i, miso_i;
assign mosi_i = mosi;
assign miso_i = miso;

always @(posedge clk or posedge rst) begin
    if (rst) begin
        sclk_stage2     <= 1'b0;
        cs_n_stage2     <= 1'b1;
        prbs_reg_stage2 <= PRBS_SEED;
        tx_data_stage2  <= 8'b0;
        rx_data_stage2  <= 8'b0;
        bit_cnt_stage2  <= 4'b0;
        mosi_o_stage2   <= 1'b0;
        miso_o_stage2   <= 1'b0;
        valid_stage2    <= 1'b0;
        flush_stage2    <= 1'b1;
    end else begin
        sclk_stage2     <= sclk_stage1;
        cs_n_stage2     <= cs_n_stage1;
        prbs_reg_stage2 <= prbs_reg_stage1;
        valid_stage2    <= valid_stage1;
        flush_stage2    <= flush_stage1;
        if (cs_n_stage1) begin
            tx_data_stage2 <= 8'b0;
            rx_data_stage2 <= 8'b0;
            bit_cnt_stage2 <= 4'b0;
        end else if (valid_stage1 & ~flush_stage1) begin
            tx_data_stage2 <= tx_data_stage2;
            rx_data_stage2 <= rx_data_stage2;
            bit_cnt_stage2 <= bit_cnt_stage2;
        end
        mosi_o_stage2 <= (external_loop) ? miso_i : (loopback_en ? prbs_bit_stage1 : 1'bz);
        miso_o_stage2 <= (loopback_en & ~external_loop) ? mosi_i : 1'bz;
    end
end

wire prbs_bit_stage2 = prbs_reg_stage2[0];

// ==========================
// Stage 3: TX/RX, Data Shift, Error Detection
// ==========================
reg sclk_stage3;
reg cs_n_stage3;
reg [31:0] prbs_reg_stage3;
reg [7:0] tx_data_stage3;
reg [7:0] rx_data_stage3;
reg [3:0] bit_cnt_stage3;
reg mosi_o_stage3, miso_o_stage3;
reg mosi_dir_stage3, miso_dir_stage3;
reg valid_stage3;
reg flush_stage3;
reg error_flag_stage3;

always @(posedge clk or posedge rst) begin
    if (rst) begin
        sclk_stage3      <= 1'b0;
        cs_n_stage3      <= 1'b1;
        prbs_reg_stage3  <= PRBS_SEED;
        tx_data_stage3   <= 8'b0;
        rx_data_stage3   <= 8'b0;
        bit_cnt_stage3   <= 4'b0;
        mosi_o_stage3    <= 1'b0;
        miso_o_stage3    <= 1'b0;
        mosi_dir_stage3  <= 1'b0;
        miso_dir_stage3  <= 1'b0;
        valid_stage3     <= 1'b0;
        flush_stage3     <= 1'b1;
        error_flag_stage3<= 1'b0;
    end else begin
        sclk_stage3      <= sclk_stage2;
        cs_n_stage3      <= cs_n_stage2;
        prbs_reg_stage3  <= prbs_reg_stage2;
        valid_stage3     <= valid_stage2;
        flush_stage3     <= flush_stage2;
        mosi_o_stage3    <= mosi_o_stage2;
        miso_o_stage3    <= miso_o_stage2;
        mosi_dir_stage3  <= (external_loop) ? 1'b0 : (loopback_en ? 1'b1 : 1'b0);
        miso_dir_stage3  <= (loopback_en & ~external_loop) ? 1'b1 : 1'b0;
        if (cs_n_stage2) begin
            tx_data_stage3   <= 8'b0;
            rx_data_stage3   <= 8'b0;
            bit_cnt_stage3   <= 4'b0;
            error_flag_stage3<= 1'b0;
        end else if (valid_stage2 & ~flush_stage2) begin
            tx_data_stage3   <= {tx_data_stage2[6:0], prbs_bit_stage2};
            rx_data_stage3   <= {rx_data_stage2[6:0], miso_i};
            bit_cnt_stage3   <= bit_cnt_stage2 + 1'b1;
            if (bit_cnt_stage2 == 4'd7 && loopback_en)
                error_flag_stage3 <= (tx_data_stage2 != rx_data_stage2);
            else
                error_flag_stage3 <= 1'b0;
        end else begin
            error_flag_stage3<= 1'b0;
        end
    end
end

// ==========================
// Stage 4: Error Flag, Error Counter (output stage)
// ==========================
reg error_flag_stage4;
reg [7:0] error_count_stage4;
always @(posedge clk or posedge rst) begin
    if (rst) begin
        error_flag_stage4   <= 1'b0;
        error_count_stage4  <= 8'b0;
        error_flag          <= 1'b0;
    end else begin
        error_flag_stage4 <= error_flag_stage3;
        error_flag        <= error_flag_stage4;
        if (error_flag_stage3)
            error_count_stage4 <= error_count_stage4 + 1'b1;
    end
end

assign error_count = error_count_stage4;

// ==========================
// SPI Output and IO Buffering
// ==========================
assign sclk = sclk_stage3;
assign cs_n = cs_n_stage3;
assign mosi = (mosi_dir_stage3) ? mosi_o_stage3 : 1'bz;
assign miso = (miso_dir_stage3) ? miso_o_stage3 : 1'bz;

endmodule
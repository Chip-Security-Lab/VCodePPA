//SystemVerilog
module SPI_Loopback #(
    parameter PRBS_SEED = 32'h12345678
)(
    input clk, rst,
    input loopback_en,
    input external_loop,
    output reg error_flag,
    output [7:0] error_count,
    // SPI接口
    output sclk, cs_n,
    inout mosi,
    inout miso
);

// 前移寄存器: 移动prbs_reg, tx_data, rx_data, bit_cnt, error_flag靠近输入端的寄存器到组合逻辑之后

reg [31:0] prbs_reg_next, prbs_reg;
wire prbs_bit;
reg [7:0] tx_data_next, tx_data;
reg [7:0] rx_data_next, rx_data;
reg [3:0] bit_cnt_next, bit_cnt;
reg error_flag_next;
reg sclk_int, sclk_int_next;
reg cs_n_int, cs_n_int_next;

// SPI时钟与片选寄存器
always @(posedge clk or posedge rst) begin
    if (rst) begin
        sclk_int <= 1'b0;
        cs_n_int <= 1'b1;
    end else begin
        sclk_int <= sclk_int_next;
        cs_n_int <= cs_n_int_next;
    end
end

// SPI时钟生成
always @(*) begin
    sclk_int_next = ~sclk_int;
end

assign sclk = sclk_int;
assign cs_n = cs_n_int;

// 片选控制逻辑
always @(*) begin
    if (rst)
        cs_n_int_next = 1'b1;
    else if (loopback_en)
        cs_n_int_next = 1'b0;
    else
        cs_n_int_next = 1'b1;
end

// PRBS逻辑/回环/错误检测前向重定时：组合逻辑产生next值，寄存于sclk_int正沿
assign prbs_bit = prbs_reg[0];

// 回环逻辑
assign mosi = (external_loop) ? miso : (loopback_en) ? prbs_bit : 1'bz;
assign miso = (loopback_en & !external_loop) ? mosi : 1'bz;

always @(*) begin
    // 默认保持
    prbs_reg_next = prbs_reg;
    tx_data_next  = tx_data;
    rx_data_next  = rx_data;
    bit_cnt_next  = bit_cnt;
    error_flag_next = error_flag;

    if (cs_n_int) begin
        prbs_reg_next = PRBS_SEED;
        tx_data_next  = 8'b0;
        rx_data_next  = 8'b0;
        bit_cnt_next  = 4'd0;
        error_flag_next = 1'b0;
    end else begin
        prbs_reg_next = {prbs_reg[30:0], prbs_reg[3] ^ prbs_reg[5]};
        tx_data_next  = {tx_data[6:0], prbs_bit};
        rx_data_next  = {rx_data[6:0], miso};
        bit_cnt_next  = bit_cnt + 1'b1;
        if ((bit_cnt == 7) && loopback_en)
            error_flag_next = (tx_data != rx_data);
        else
            error_flag_next = error_flag;
    end
end

always @(posedge sclk_int) begin
    prbs_reg   <= prbs_reg_next;
    tx_data    <= tx_data_next;
    rx_data    <= rx_data_next;
    bit_cnt    <= bit_cnt_next;
    error_flag <= error_flag_next;
end

// 错误计数器
reg [7:0] err_counter;
always @(posedge clk or posedge rst) begin
    if (rst) begin
        err_counter <= 8'b0;
    end else if (error_flag) begin
        err_counter <= err_counter + 1'b1;
    end
end
assign error_count = err_counter;

endmodule
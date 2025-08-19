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

reg [31:0] prbs_reg;
wire prbs_bit = prbs_reg[0];
reg [7:0] tx_data;
reg [7:0] rx_data;
reg [3:0] bit_cnt;
reg sclk_int;
reg cs_n_int;

// PRBS生成器
always @(posedge sclk_int) begin
    if(cs_n_int) begin
        prbs_reg <= PRBS_SEED;
    end else begin
        prbs_reg <= {prbs_reg[30:0], prbs_reg[3] ^ prbs_reg[5]};
    end
end

// 回环逻辑
assign mosi = (external_loop) ? miso : (loopback_en) ? prbs_bit : 1'bz;
assign miso = (loopback_en & !external_loop) ? mosi : 1'bz;

// 错误检测 - 添加bit_cnt递增
always @(posedge sclk_int) begin
    if(cs_n_int) begin
        bit_cnt <= 0;
    end else begin
        tx_data <= {tx_data[6:0], prbs_bit};
        rx_data <= {rx_data[6:0], miso};
        bit_cnt <= bit_cnt + 1;
        if(bit_cnt == 7 && loopback_en) begin
            error_flag <= (tx_data != rx_data);
        end
    end
end

// 错误计数器
reg [7:0] err_counter;
always @(posedge clk or posedge rst) begin
    if(rst) begin
        err_counter <= 0;
    end else if(error_flag) begin
        err_counter <= err_counter + 1;
    end
end
assign error_count = err_counter;

// 生成SPI时钟
always @(posedge clk) begin
    sclk_int <= ~sclk_int;
end
assign sclk = sclk_int;
assign cs_n = cs_n_int;

// 简单的测试控制
always @(posedge clk or posedge rst) begin
    if(rst) begin
        cs_n_int <= 1'b1;
    end else if(loopback_en) begin
        cs_n_int <= 1'b0;
    end else begin
        cs_n_int <= 1'b1;
    end
end
endmodule
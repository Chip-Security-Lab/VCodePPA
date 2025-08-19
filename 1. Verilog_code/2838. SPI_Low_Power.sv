module SPI_Low_Power #(
    parameter CLK_GATING = 1
)(
    input clk, rst_n,
    input sleep,
    input [7:0] tx_data,
    output [7:0] rx_data,
    output reg sclk,
    inout mosi,
    input miso,
    output reg cs_n
);

reg clk_en;
reg [7:0] shift_reg;
reg [2:0] bit_cnt;
reg clk_gated;

// 时钟门控逻辑
always @(*) begin
    if (CLK_GATING) 
        clk_gated = clk_en & clk;
    else 
        clk_gated = clk;
end

always @(posedge clk_gated or negedge rst_n) begin
    if (!rst_n) begin
        shift_reg <= 8'h00;
        bit_cnt <= 0;
        cs_n <= 1'b1;
    end else begin
        if (!sleep) begin
            if (bit_cnt == 0 && !cs_n) begin
                shift_reg <= tx_data;
                sclk <= 1'b0;
            end
            // 数据传输逻辑...
        end
    end
end

// 电源状态控制
always @(posedge clk) begin
    clk_en <= ~sleep & ~cs_n;
end
endmodule

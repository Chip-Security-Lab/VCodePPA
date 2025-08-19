//SystemVerilog
`timescale 1ns / 1ps
module sync_rst_high #(
    parameter DATA_WIDTH = 8
) (
    input  wire                  clk,
    input  wire                  rst_n,
    input  wire                  en,
    input  wire [DATA_WIDTH-1:0] data_in,
    output reg  [DATA_WIDTH-1:0] data_out
);

    // 优化的复位和使能逻辑 - 使用case结构
    always @(posedge clk) begin
        case ({rst_n, en})
            2'b00: data_out <= {DATA_WIDTH{1'b0}}; // 复位有效
            2'b01: data_out <= {DATA_WIDTH{1'b0}}; // 复位有效，使能无关
            2'b10: data_out <= data_out;          // 复位无效，使能无效，保持当前值
            2'b11: data_out <= data_in;           // 复位无效，使能有效，更新输出
            default: data_out <= data_out;        // 默认保持当前值
        endcase
    end

endmodule
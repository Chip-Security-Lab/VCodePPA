//SystemVerilog (IEEE 1364-2005)
module sync_rst_high #(
    parameter DATA_WIDTH = 8
) (
    input  wire                  clk,
    input  wire                  rst_n,
    input  wire                  en,
    input  wire [DATA_WIDTH-1:0] data_in,
    output reg  [DATA_WIDTH-1:0] data_out
);

    // 直接在顶层模块中实现逻辑，减少层次结构
    // 同步复位寄存器与数据选择逻辑合并
    always @(posedge clk) begin
        if (!rst_n) begin
            // 同步高电平复位
            data_out <= {DATA_WIDTH{1'b0}};
        end else if (en) begin
            // 只在使能有效时更新寄存器值，减少不必要的切换
            data_out <= data_in;
        end
    end

endmodule
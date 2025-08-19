//SystemVerilog
module shadow_reg_dynamic #(
    parameter MAX_WIDTH = 16
)(
    input  wire                 clk,
    input  wire [3:0]           width_sel,
    input  wire [MAX_WIDTH-1:0] data_in,
    output reg  [MAX_WIDTH-1:0] data_out
);
    // 数据流水线阶段1: 输入注册
    reg [MAX_WIDTH-1:0] data_in_reg;
    // 数据流水线阶段2: 影子寄存器
    reg [MAX_WIDTH-1:0] shadow_reg;
    // 掩码生成寄存器
    reg [MAX_WIDTH-1:0] width_mask;

    // 数据流第一阶段: 输入捕获和掩码计算
    always @(posedge clk) begin
        // 注册输入数据，提高时序性能
        data_in_reg <= data_in;
        // 预计算位宽掩码，分离控制路径和数据路径
        width_mask <= (1'b1 << width_sel) - 1'b1;
    end

    // 数据流第二阶段: 影子寄存器和掩码应用
    always @(posedge clk) begin
        // 更新影子寄存器
        shadow_reg <= data_in_reg;
        // 应用掩码到影子寄存器并输出
        data_out <= shadow_reg & width_mask;
    end

endmodule
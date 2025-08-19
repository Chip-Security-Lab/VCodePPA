//SystemVerilog
module ConfigurableNOT(
    input wire clk,           // 时钟信号
    input wire rst_n,         // 复位信号，低电平有效
    input wire pol,           // 极性控制
    input wire [7:0] in,      // 输入数据
    output reg [7:0] out      // 输出数据
);
    // 内部信号定义
    reg pol_r1, pol_r2;       // 极性控制信号流水线寄存
    reg [7:0] in_r1, in_r2;   // 输入数据流水线寄存
    reg [7:0] not_result_r;   // 非门操作结果寄存
    wire [7:0] not_result;    // 非门操作结果
    reg [7:0] mux_result;     // 选择器结果

    // 输入寄存级 - 第一级流水线
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            pol_r1 <= 1'b0;
            in_r1 <= 8'h00;
        end else begin
            pol_r1 <= pol;
            in_r1 <= in;
        end
    end

    // 第二级流水线 - 增加寄存以切割关键路径
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            pol_r2 <= 1'b0;
            in_r2 <= 8'h00;
        end else begin
            pol_r2 <= pol_r1;
            in_r2 <= in_r1;
        end
    end

    // 计算非门结果 - 纯组合逻辑
    assign not_result = ~in_r2;

    // 将非门结果寄存 - 第三级流水线
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            not_result_r <= 8'h00;
        end else begin
            not_result_r <= not_result;
        end
    end

    // 选择器级 - 基于极性控制选择输出
    always @(*) begin
        mux_result = pol_r2 ? not_result_r : in_r2;
    end

    // 输出寄存级 - 最终输出
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            out <= 8'h00;
        end else begin
            out <= mux_result;
        end
    end

endmodule
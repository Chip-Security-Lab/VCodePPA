//SystemVerilog
module jkff #(parameter W=1) (
    input wire clk,         // 时钟信号
    input wire rstn,        // 低电平有效复位
    input wire [W-1:0] j,   // J输入
    input wire [W-1:0] k,   // K输入
    output reg [W-1:0] q    // 输出
);
    // 内部信号定义 - 将数据路径分段
    reg [W-1:0] j_path;     // J输入路径
    reg [W-1:0] k_path;     // K输入路径
    reg [W-1:0] next_q;     // 下一状态逻辑

    // 输入路径寄存
    always @(posedge clk or negedge rstn) begin
        if (!rstn) begin
            j_path <= {W{1'b0}};
            k_path <= {W{1'b0}};
        end else begin
            j_path <= j;
            k_path <= k;
        end
    end

    // 下一状态逻辑计算 - 组合逻辑
    always @(*) begin
        next_q = (~q & j_path) | (q & ~k_path);
    end

    // 状态更新 - 输出寄存
    always @(posedge clk or negedge rstn) begin
        if (!rstn) begin
            q <= {W{1'b0}};
        end else begin
            q <= next_q;
        end
    end

endmodule
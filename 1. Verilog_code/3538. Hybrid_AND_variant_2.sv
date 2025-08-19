//SystemVerilog
module Hybrid_AND (
    input  wire        clk,       // 时钟信号
    input  wire        rst_n,     // 复位信号，低电平有效
    input  wire [1:0]  ctrl,      // 控制信号
    input  wire [7:0]  base,      // 输入基数
    output wire [7:0]  result     // 计算结果
);

    // 第一级流水线：计算移位量和存储输入
    reg  [1:0]  ctrl_r1;
    reg  [7:0]  base_r1;
    reg  [3:0]  shift_amount;
    
    // 第二级流水线：计算掩码
    reg  [7:0]  base_r2;
    reg  [7:0]  mask;
    
    // 第三级流水线：计算最终结果
    reg  [7:0]  result_r;
    
    // 阶段1：注册输入并计算移位量 - 扁平化if-else结构
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            ctrl_r1       <= 2'b0;
            base_r1       <= 8'h0;
            shift_amount  <= 4'h0;
        end else begin
            ctrl_r1       <= ctrl;
            base_r1       <= base;
            shift_amount  <= ctrl << 2; // 等价于 ctrl * 4
        end
    end
    
    // 阶段2：生成掩码 - 扁平化if-else结构
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            base_r2 <= 8'h0;
            mask    <= 8'h0;
        end else begin
            base_r2 <= base_r1;
            mask    <= 8'h0F << shift_amount;
        end
    end
    
    // 阶段3：计算最终AND结果 - 扁平化if-else结构
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            result_r <= 8'h0;
        end else begin
            result_r <= base_r2 & mask;
        end
    end
    
    // 输出赋值
    assign result = result_r;

endmodule
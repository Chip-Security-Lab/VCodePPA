//SystemVerilog
module complex_logic (
    input wire clk,           // 添加时钟信号
    input wire rst_n,         // 添加复位信号
    input wire [3:0] a, b, c,
    output reg [3:0] res1,
    output reg [3:0] res2
);
    // 阶段1: 初始操作 - 分离操作路径
    reg [3:0] a_or_b;
    reg [3:0] a_xor_b;
    reg [3:0] c_stage1;
    
    // 阶段2: 中间结果寄存器
    reg [3:0] and_result;
    reg [3:0] c_stage2;
    reg [3:0] xor_result;
    
    // 阶段1: 并行计算基本逻辑操作
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            a_or_b <= 4'b0;
            a_xor_b <= 4'b0;
            c_stage1 <= 4'b0;
        end else begin
            a_or_b <= a | b;     // 逻辑或运算
            a_xor_b <= a ^ b;    // 异或运算
            c_stage1 <= c;       // 传递c到下一阶段
        end
    end
    
    // 阶段2: 执行中间运算
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            and_result <= 4'b0;
            xor_result <= 4'b0;
            c_stage2 <= 4'b0;
        end else begin
            and_result <= a_or_b & c_stage1;  // 进行与运算
            xor_result <= a_xor_b;            // 传递异或结果
            c_stage2 <= c_stage1;             // 传递c到下一阶段
        end
    end
    
    // 阶段3: 生成最终结果
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            res1 <= 4'b0;
            res2 <= 4'b0;
        end else begin
            res1 <= and_result;              // 传递与运算结果
            res2 <= xor_result + c_stage2;   // 执行加法运算
        end
    end
    
endmodule
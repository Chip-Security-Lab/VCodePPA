//SystemVerilog
module recursive_shifter #(parameter N=16) (
    input [N-1:0] data,
    input [$clog2(N)-1:0] shift,
    output [N-1:0] result
);
    localparam LOG2_N = $clog2(N);
    
    // 使用参数化方式定义阶段间连接
    wire [N-1:0] stage [0:LOG2_N];
    
    // 减法器相关信号
    wire [7:0] subtractor_operand_a;
    wire [7:0] subtractor_operand_b;
    wire subtractor_cin;
    wire [7:0] subtractor_result;
    wire [7:0] operand_b_modified;
    wire [7:0] not_operand_b;
    
    // 初始阶段
    assign stage[0] = data;
    
    // 条件反相减法器实现
    assign subtractor_operand_a = stage[0][7:0];
    assign subtractor_operand_b = {8{shift[0]}}; // 根据移位控制选择减数
    assign subtractor_cin = shift[0];  // 减法时进位输入为1
    
    // 对B操作数条件反相
    assign not_operand_b = ~subtractor_operand_b;
    assign operand_b_modified = subtractor_cin ? not_operand_b : subtractor_operand_b;
    
    // 执行加法操作 (A + B' + Cin 实现减法)
    assign subtractor_result = subtractor_operand_a + operand_b_modified + subtractor_cin;
    
    // 生成所有移位阶段
    genvar i;
    generate
        for (i = 0; i < LOG2_N; i = i + 1) begin : shift_stage
            // 计算当前阶段的移位位数
            localparam SHIFT_AMT = 1 << i;
            
            if (i == 0) begin
                // 第一阶段使用条件反相减法器的结果
                assign stage[i+1] = shift[i] ? 
                    {subtractor_result, stage[i][N-1:8]} : 
                    stage[i];
            end else begin
                // 后续阶段保持原有的移位逻辑
                assign stage[i+1] = shift[i] ? 
                    {stage[i][N-SHIFT_AMT-1:0], stage[i][N-1:N-SHIFT_AMT]} : 
                    stage[i];
            end
        end
    endgenerate
    
    // 最终输出
    assign result = stage[LOG2_N];
endmodule
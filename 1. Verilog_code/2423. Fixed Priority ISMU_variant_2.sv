//SystemVerilog
//IEEE 1364-2005 Verilog
module priority_fixed_ismu #(parameter INT_COUNT = 16)(
    input clk, reset,
    input [INT_COUNT-1:0] int_src,
    input [INT_COUNT-1:0] int_enable,
    output reg [3:0] priority_num,
    output reg int_active
);
    // 预先计算所有中断源的有效状态
    wire [INT_COUNT-1:0] int_valid;
    reg [3:0] next_priority_num;
    reg next_int_active;
    
    // 组合逻辑前移，计算下一个状态
    assign int_valid = int_src & int_enable;
    
    // 查找表辅助减法器实现优先级编码器
    // 减法器查找表 - 存储4位减法结果
    reg [3:0] subtractor_lut [0:15][0:15];
    reg [3:0] operand_a, operand_b;
    wire [3:0] subtraction_result;
    reg [3:0] priority_encoder_value;
    reg [3:0] highest_priority;
    
    // 减法器查找表初始化
    integer i, j;
    initial begin
        for (i = 0; i < 16; i = i + 1) begin
            for (j = 0; j < 16; j = j + 1) begin
                subtractor_lut[i][j] = i - j; // 预计算所有可能的4位减法结果
            end
        end
    end
    
    // 使用查找表执行减法
    assign subtraction_result = subtractor_lut[operand_a][operand_b];
    
    // 优先级编码逻辑，使用查找表减法操作来确定最高优先级
    always @(*) begin
        next_int_active = |int_valid; // 任一中断有效则激活
        highest_priority = 4'hF; // 初始最高优先级
        next_priority_num = 4'h0;
        
        for (i = 0; i < INT_COUNT && i < 16; i = i + 1) begin
            if (int_valid[i]) begin
                operand_a = highest_priority;
                operand_b = i[3:0];
                
                // 如果当前中断索引小于已存的最高优先级
                if (subtraction_result[3] == 1'b0 && operand_a != operand_b) begin
                    highest_priority = i[3:0];
                    next_priority_num = i[3:0];
                end
            end
        end
    end
    
    // 寄存器逻辑
    always @(posedge clk) begin
        if (reset) begin
            priority_num <= 4'h0;
            int_active <= 1'b0;
        end else begin
            priority_num <= next_priority_num;
            int_active <= next_int_active;
        end
    end
endmodule
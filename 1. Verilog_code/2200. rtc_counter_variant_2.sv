//SystemVerilog
module rtc_counter #(
    parameter WIDTH = 32
)(
    input wire clk_i,
    input wire rst_i,
    input wire en_i,
    output reg rollover_o,
    output wire [WIDTH-1:0] count_o
);
    // 计数器状态寄存器
    reg [WIDTH/2-1:0] counter_lower;
    reg [WIDTH/2-1:0] counter_upper;
    
    // 输出分配
    assign count_o = {counter_upper, counter_lower};
    
    // 使能信号流水线
    reg en_stage1, en_stage2;
    
    // 查找表输入状态组合
    wire [3:0] state_index;
    assign state_index = {en_i, en_stage1, lower_carry, en_stage2 & (&counter_upper) & (&counter_lower)};
    
    // 计算进位条件
    wire lower_carry = en_i && &counter_lower;
    wire upper_carry = en_stage1 && lower_carry;
    
    // 查找表输出信号
    reg [WIDTH/2-1:0] next_lower;
    reg [WIDTH/2-1:0] next_upper;
    reg next_rollover;
    
    // 查找表实现 - 替代复杂条件逻辑
    always @(*) begin
        // 默认值
        next_lower = counter_lower;
        next_upper = counter_upper;
        next_rollover = 1'b0;
        
        // 查找表索引访问
        case (state_index)
            // {en_i, en_stage1, lower_carry, rollover_condition}
            4'b0000, 4'b0001, 4'b0010, 4'b0011: begin
                // 使能关闭，保持当前值
                next_lower = counter_lower;
                next_upper = counter_upper;
                next_rollover = 1'b0;
            end
            
            4'b1000: begin
                // 仅低位计数，无进位
                next_lower = counter_lower + 1'b1;
                next_upper = counter_upper;
                next_rollover = 1'b0;
            end
            
            4'b1010: begin
                // 低位计数并产生进位，但上级未响应
                next_lower = {(WIDTH/2){1'b0}};
                next_upper = counter_upper;
                next_rollover = 1'b0;
            end
            
            4'b1110: begin
                // 低位计数并产生进位，上级响应但无溢出
                next_lower = {(WIDTH/2){1'b0}};
                next_upper = counter_upper + 1'b1;
                next_rollover = 1'b0;
            end
            
            4'b1111: begin
                // 溢出条件
                next_lower = {(WIDTH/2){1'b0}};
                next_upper = {(WIDTH/2){1'b0}};
                next_rollover = 1'b1;
            end
            
            default: begin
                // 其他情况，保持值
                next_lower = counter_lower;
                next_upper = counter_upper;
                next_rollover = 1'b0;
            end
        endcase
    end
    
    // 使能信号流水线
    always @(posedge clk_i) begin
        if (rst_i) begin
            en_stage1 <= 1'b0;
            en_stage2 <= 1'b0;
        end else begin
            en_stage1 <= en_i;
            en_stage2 <= en_stage1;
        end
    end
    
    // 计数器状态更新
    always @(posedge clk_i) begin
        if (rst_i) begin
            counter_lower <= {(WIDTH/2){1'b0}};
            counter_upper <= {(WIDTH/2){1'b0}};
            rollover_o <= 1'b0;
        end else begin
            counter_lower <= next_lower;
            counter_upper <= next_upper;
            rollover_o <= next_rollover;
        end
    end
endmodule
//SystemVerilog
module async_mult (
    input [3:0] A, B,
    output [7:0] P,
    input start,
    output done
);
    // 异步状态机实现
    reg [2:0] state, next_state;
    reg [3:0] multiplicand;
    reg [3:0] multiplier;
    reg [7:0] product;
    reg done_reg;
    
    parameter IDLE = 3'b000;
    parameter INIT = 3'b001;
    parameter ADD = 3'b010;
    parameter SHIFT = 3'b011;
    parameter FINISH = 3'b100;
    
    reg [2:0] counter;
    
    // 流水线寄存器
    reg [3:0] multiplicand_pipe;
    reg [3:0] multiplier_pipe;
    reg [7:0] product_pipe;
    reg [2:0] counter_pipe;
    reg add_valid;
    
    // 状态转换逻辑 - 使用组合逻辑计算下一状态
    always @(*) begin
        next_state = state; // 默认保持当前状态
        
        case(state)
            IDLE: next_state = start ? INIT : IDLE;
            INIT: next_state = ADD;
            ADD: next_state = SHIFT;
            SHIFT: next_state = (counter_pipe == 3'b011) ? FINISH : ADD;
            FINISH: next_state = IDLE;
            default: next_state = IDLE;
        endcase
    end
    
    // 状态寄存器 - 使用时序逻辑更新状态
    always @(posedge start or negedge done_reg) begin
        if (!done_reg)
            state <= next_state;
        else if (start)
            state <= next_state;
    end
    
    // 数据处理逻辑 - 使用组合逻辑
    always @(*) begin
        // 默认值
        done_reg = 1'b1;
        add_valid = 1'b0;
        
        case(state)
            IDLE: begin
                counter = 3'b000;
            end
            
            INIT: begin
                multiplicand = A;
                multiplier = B;
                product = 8'b0;
                counter = 3'b000;
                done_reg = 1'b0;
            end
            
            ADD: begin
                done_reg = 1'b0;
                add_valid = 1'b1;
            end
            
            SHIFT: begin
                done_reg = 1'b0;
                multiplier = multiplier_pipe >> 1;
                product = product_pipe >> 1;
                counter = counter_pipe + 1;
            end
            
            FINISH: begin
                done_reg = 1'b1;
            end
            
            default: begin
                done_reg = 1'b1;
            end
        endcase
    end
    
    // 流水线寄存器更新
    always @(posedge start or negedge done_reg) begin
        if (!done_reg) begin
            multiplicand_pipe <= multiplicand;
            multiplier_pipe <= multiplier;
            counter_pipe <= counter;
            
            if (add_valid && multiplier[0])
                product_pipe <= product[7:4] + multiplicand;
            else
                product_pipe <= product;
        end
    end
    
    // 输出赋值
    assign P = product;
    assign done = done_reg;
endmodule
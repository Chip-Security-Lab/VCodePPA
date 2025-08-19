//SystemVerilog
module mod_exp #(parameter WIDTH = 16) (
    input wire clk, reset,
    input wire start,
    input wire [WIDTH-1:0] base, exponent, modulus,
    output reg [WIDTH-1:0] result,
    output reg done
);
    // 状态定义
    localparam IDLE = 2'b00;
    localparam CALC = 2'b01;
    localparam DONE = 2'b10;
    
    // 控制路径信号
    reg [1:0] state, next_state;
    reg start_calc;
    reg calc_done;
    
    // 数据路径信号
    reg [WIDTH-1:0] exp_reg, next_exp;
    reg [WIDTH-1:0] base_reg, next_base;
    reg [WIDTH-1:0] result_reg, next_result;
    reg done_reg, next_done;
    
    // 流水线寄存器
    reg [WIDTH-1:0] mult_a, mult_b;
    reg [WIDTH-1:0] mult_result_stage1;
    reg [WIDTH-1:0] squared_base_stage1;
    reg exp_bit_stage1;
    
    // 模运算流水线寄存器
    reg [WIDTH-1:0] mod_input_stage1;
    reg [WIDTH-1:0] mod_result_stage2;
    
    // 控制信号
    wire exp_lsb = exp_reg[0];
    wire exp_done = (exp_reg == 0);
    
    // ===================================
    // 控制路径：状态机逻辑
    // ===================================
    always @(*) begin
        next_state = state;
        start_calc = 1'b0;
        calc_done = 1'b0;
        
        case(state)
            IDLE: begin
                if (start) begin
                    next_state = CALC;
                    start_calc = 1'b1;
                end
            end
            
            CALC: begin
                if (exp_done) begin
                    next_state = DONE;
                    calc_done = 1'b1;
                end
            end
            
            DONE: begin
                if (start) begin
                    next_state = CALC;
                    start_calc = 1'b1;
                end else begin
                    next_state = IDLE;
                end
            end
            
            default: next_state = IDLE;
        endcase
    end
    
    // ===================================
    // 数据路径：流水线第一级 - 乘法与平方运算
    // ===================================
    always @(posedge clk) begin
        if (reset) begin
            mult_a <= 0;
            mult_b <= 0;
            exp_bit_stage1 <= 0;
        end else begin
            // 乘法操作数准备
            mult_a <= result_reg;
            mult_b <= base_reg;
            exp_bit_stage1 <= exp_lsb;
        end
    end
    
    // ===================================
    // 数据路径：流水线第二级 - 计算结果
    // ===================================
    always @(posedge clk) begin
        if (reset) begin
            mult_result_stage1 <= 0;
            squared_base_stage1 <= 0;
        end else begin
            // 计算乘法结果和平方结果
            mult_result_stage1 <= (mult_a * mult_b);
            squared_base_stage1 <= (base_reg * base_reg);
        end
    end
    
    // ===================================
    // 数据路径：流水线第三级 - 模运算
    // ===================================
    always @(posedge clk) begin
        if (reset) begin
            mod_input_stage1 <= 0;
        end else begin
            // 选择需要进行模运算的输入
            mod_input_stage1 <= exp_bit_stage1 ? mult_result_stage1 : result_reg;
        end
    end
    
    // ===================================
    // 数据路径：流水线第四级 - 模运算结果
    // ===================================
    always @(posedge clk) begin
        if (reset) begin
            mod_result_stage2 <= 0;
        end else begin
            // 计算模运算结果
            mod_result_stage2 <= mod_input_stage1 % modulus;
        end
    end
    
    // ===================================
    // 数据路径：下一状态计算
    // ===================================
    always @(*) begin
        // 默认保持当前值
        next_exp = exp_reg;
        next_base = base_reg;
        next_result = result_reg;
        next_done = done_reg;
        
        if (start_calc) begin
            // 初始化计算
            next_exp = exponent;
            next_base = base;
            next_result = 1;
            next_done = 0;
        end else if (state == CALC) begin
            // 更新结果和移位指数
            next_result = mod_result_stage2;
            next_base = squared_base_stage1 % modulus;
            next_exp = exp_reg >> 1;
        end else if (calc_done) begin
            // 设置完成标志
            next_done = 1;
        end
    end
    
    // ===================================
    // 寄存器更新
    // ===================================
    always @(posedge clk) begin
        if (reset) begin
            state <= IDLE;
            exp_reg <= 0;
            base_reg <= 0;
            result_reg <= 1;
            done_reg <= 0;
        end else begin
            state <= next_state;
            exp_reg <= next_exp;
            base_reg <= next_base;
            result_reg <= next_result;
            done_reg <= next_done;
        end
    end
    
    // 输出赋值
    always @(*) begin
        result = result_reg;
        done = done_reg;
    end
    
endmodule
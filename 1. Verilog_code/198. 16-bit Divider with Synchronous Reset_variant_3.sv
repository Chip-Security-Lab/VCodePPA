//SystemVerilog
module divider_sync_reset (
    input clk,
    input reset,
    input [15:0] dividend,
    input [15:0] divisor,
    output reg [15:0] quotient,
    output reg [15:0] remainder
);

    // Internal registers for Goldschmidt algorithm
    reg [31:0] x, d;
    reg [31:0] f, f_next;
    reg [3:0] iteration_count;
    reg [15:0] dividend_reg, divisor_reg;
    
    // Constants
    localparam ITERATIONS = 5;
    
    // FSM states
    localparam IDLE = 2'b00;
    localparam COMPUTE = 2'b01;
    localparam FINALIZE = 2'b10;
    reg [1:0] state, next_state;
    
    // 计算信号
    wire divisor_zero;
    reg start_compute;
    reg compute_iteration;
    reg finalize_result;
    
    // 状态检测逻辑
    assign divisor_zero = (divisor == 0);
    
    // 状态转换逻辑
    always @(*) begin
        next_state = state;
        start_compute = 1'b0;
        compute_iteration = 1'b0;
        finalize_result = 1'b0;
        
        case (state)
            IDLE: begin
                if (!divisor_zero) begin
                    next_state = COMPUTE;
                    start_compute = 1'b1;
                end
            end
            
            COMPUTE: begin
                compute_iteration = 1'b1;
                if (iteration_count >= ITERATIONS - 1) begin
                    next_state = FINALIZE;
                end
            end
            
            FINALIZE: begin
                finalize_result = 1'b1;
                next_state = IDLE;
            end
        endcase
    end
    
    // 状态寄存器更新
    always @(posedge clk or posedge reset) begin
        if (reset) begin
            state <= IDLE;
        end else begin
            state <= next_state;
        end
    end
    
    // 初始化和输入寄存
    always @(posedge clk or posedge reset) begin
        if (reset) begin
            dividend_reg <= 0;
            divisor_reg <= 0;
        end else if (start_compute) begin
            dividend_reg <= dividend;
            divisor_reg <= divisor;
        end
    end
    
    // 算法迭代计数器
    always @(posedge clk or posedge reset) begin
        if (reset) begin
            iteration_count <= 0;
        end else if (start_compute) begin
            iteration_count <= 0;
        end else if (compute_iteration) begin
            iteration_count <= iteration_count + 1;
        end
    end
    
    // Goldschmidt算法初始化
    always @(posedge clk or posedge reset) begin
        if (reset) begin
            x <= 0;
            d <= 0;
            f <= 0;
            f_next <= 0;
        end else if (start_compute) begin
            // Initialize values for Goldschmidt algorithm
            x <= {dividend, 16'b0};     // Extend to 32 bits
            d <= {16'b0, divisor};      // Extend to 32 bits
            f <= 32'h00010000;          // Initialize f = 1.0 in fixed point
            f_next <= 32'h00010000;     // Pre-initialize f_next
        end
    end
    
    // Goldschmidt算法迭代计算
    always @(posedge clk or posedge reset) begin
        if (reset) begin
            f <= 0;
            f_next <= 0;
            x <= 0;
        end else if (compute_iteration) begin
            // Goldschmidt iteration: f = f * (2 - d*f)
            f_next <= f * (32'h00020000 - ((d * f) >> 16));
            f <= f_next;
            // And x = x * f
            x <= (x * f_next) >> 16;
        end
    end
    
    // 结果计算逻辑
    always @(posedge clk or posedge reset) begin
        if (reset) begin
            quotient <= 0;
            remainder <= 0;
        end else if (divisor_zero && state == IDLE) begin
            // Division by zero case
            quotient <= 16'hFFFF;   // Max value for division by zero
            remainder <= dividend;
        end else if (finalize_result) begin
            // Final quotient is in x
            quotient <= x[31:16];
            // Calculate remainder as dividend - quotient * divisor
            remainder <= dividend_reg - (x[31:16] * divisor_reg);
        end
    end

endmodule
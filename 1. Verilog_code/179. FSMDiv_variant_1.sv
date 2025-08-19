//SystemVerilog
module FSMDiv(
    input clk, start,
    input [15:0] dividend, divisor,
    output reg [15:0] quotient,
    output done
);
    // 状态定义 - 使用参数提高可读性
    parameter IDLE = 2'b00;
    parameter COMPUTE = 2'b01;
    parameter DONE = 2'b10;
    
    reg [1:0] state, next_state;
    reg [15:0] rem, next_rem;
    reg [4:0] cnt, next_cnt;
    reg load_data;
    reg compute_step;
    reg finish_op;
    
    // 状态转换逻辑
    always @(posedge clk) begin
        state <= next_state;
    end
    
    // 状态迁移控制逻辑
    always @(*) begin
        next_state = state;
        load_data = 1'b0;
        compute_step = 1'b0;
        finish_op = 1'b0;
        
        if (state == IDLE && start) begin
            next_state = COMPUTE;
            load_data = 1'b1;
        end else if (state == COMPUTE) begin
            compute_step = 1'b1;
            if (cnt == 0)
                next_state = DONE;
        end else if (state == DONE) begin
            finish_op = 1'b1;
            next_state = IDLE;
        end else begin
            next_state = IDLE;
        end
    end
    
    // 计数器逻辑
    always @(posedge clk) begin
        if (load_data)
            cnt <= 15;
        else if (compute_step)
            cnt <= cnt - 1;
    end
    
    // 余数寄存器逻辑
    always @(posedge clk) begin
        if (load_data)
            rem <= dividend;
        else if (compute_step) begin
            if (rem_shifted >= divisor)
                rem <= rem_shifted - divisor;
            else
                rem <= rem_shifted;
        end
    end
    
    // 商寄存器逻辑
    always @(posedge clk) begin
        if (load_data)
            quotient <= 16'b0;
        else if (compute_step && rem_shifted >= divisor)
            quotient[cnt] <= 1'b1;
    end
    
    // 组合逻辑 - 计算移位后的余数
    wire [15:0] rem_shifted;
    assign rem_shifted = rem << 1;
    
    // 完成信号
    assign done = (state == DONE);
endmodule
//SystemVerilog
module var_duty_pwm_clk #(
    parameter PERIOD = 16
)(
    input clk_in,
    input rst,
    input [3:0] duty,  // 0-15 (0%-93.75%)
    output reg clk_out
);
    // Stage 1 signals
    reg [$clog2(PERIOD)-1:0] counter_stage1;
    reg [3:0] duty_stage1;
    reg counter_reset_stage1;
    
    // Stage 2 signals
    reg [$clog2(PERIOD)-1:0] counter_stage2;
    reg [3:0] duty_stage2;
    
    // Pipeline control signals
    reg valid_stage1, valid_stage2;
    
    // 先行借位减法器信号
    wire [3:0] difference;
    wire [4:0] borrow;
    
    // Stage 1: Counter update logic
    always @(posedge clk_in or posedge rst) begin
        if (rst) begin
            counter_stage1 <= 0;
            duty_stage1 <= 0;
            counter_reset_stage1 <= 0;
            valid_stage1 <= 0;
        end else begin
            valid_stage1 <= 1'b1;
            duty_stage1 <= duty;
            
            if (counter_stage1 < PERIOD-1) begin
                counter_stage1 <= counter_stage1 + 1;
                counter_reset_stage1 <= 1'b0;
            end else begin
                counter_stage1 <= 0;
                counter_reset_stage1 <= 1'b1;
            end
        end
    end
    
    // 先行借位减法器实现
    assign borrow[0] = 1'b0;
    assign borrow[1] = (counter_stage2[0] < duty_stage2[0]) ? 1'b1 : 1'b0;
    assign borrow[2] = ((counter_stage2[1] < duty_stage2[1]) || 
                        (counter_stage2[1] == duty_stage2[1] && borrow[1])) ? 1'b1 : 1'b0;
    assign borrow[3] = ((counter_stage2[2] < duty_stage2[2]) || 
                        (counter_stage2[2] == duty_stage2[2] && borrow[2])) ? 1'b1 : 1'b0;
    assign borrow[4] = ((counter_stage2[3] < duty_stage2[3]) || 
                        (counter_stage2[3] == duty_stage2[3] && borrow[3])) ? 1'b1 : 1'b0;
    
    assign difference[0] = counter_stage2[0] ^ duty_stage2[0] ^ borrow[0];
    assign difference[1] = counter_stage2[1] ^ duty_stage2[1] ^ borrow[1];
    assign difference[2] = counter_stage2[2] ^ duty_stage2[2] ^ borrow[2];
    assign difference[3] = counter_stage2[3] ^ duty_stage2[3] ^ borrow[3];
    
    // Stage 2: Compare and output generation using look-ahead borrow subtractor
    always @(posedge clk_in or posedge rst) begin
        if (rst) begin
            counter_stage2 <= 0;
            duty_stage2 <= 0;
            clk_out <= 0;
            valid_stage2 <= 0;
        end else begin
            valid_stage2 <= valid_stage1;
            counter_stage2 <= counter_stage1;
            duty_stage2 <= duty_stage1;
            
            if (valid_stage2) begin
                // 使用先行借位检测结果替代原来的比较逻辑
                // counter < duty 等价于 borrow[4] = 1
                clk_out <= borrow[4] ? 1'b1 : 1'b0;
            end else begin
                clk_out <= 1'b0;
            end
        end
    end
endmodule
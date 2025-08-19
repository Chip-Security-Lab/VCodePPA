//SystemVerilog
module adaptive_pwm #(
    parameter WIDTH = 8
)(
    input clk,
    input feedback,
    output reg pwm
);
    reg [WIDTH-1:0] duty_cycle;
    reg [WIDTH-1:0] counter;
    reg compare_result;
    reg [WIDTH-1:0] next_duty_cycle;
    wire [WIDTH-1:0] borrow;
    wire [WIDTH-1:0] diff;
    
    // 先行借位减法器
    assign borrow[0] = 1'b0;
    genvar i;
    generate
        for (i = 0; i < WIDTH; i = i + 1) begin : sub_gen
            if (i < WIDTH-1) begin
                assign borrow[i+1] = (~duty_cycle[i] & borrow[i]) | (~duty_cycle[i] & 1'b1) | (borrow[i] & 1'b1);
                // 简化布尔表达式
                // assign borrow[i+1] = (~duty_cycle[i]) | borrow[i];
            end
            assign diff[i] = duty_cycle[i] ^ 1'b1 ^ borrow[i];
        end
    endgenerate
    
    // 替换选择器逻辑，使用always块和if-else结构
    always @(*) begin
        if (feedback) begin
            if (duty_cycle < {WIDTH{1'b1}})
                next_duty_cycle = duty_cycle + 1'b1;
            else
                next_duty_cycle = duty_cycle;
        end
        else begin
            if (duty_cycle > {WIDTH{1'b0}})
                next_duty_cycle = diff;
            else
                next_duty_cycle = duty_cycle;
        end
    end
    
    always @(posedge clk) begin
        compare_result <= (counter < duty_cycle);
        counter <= counter + 1;
        pwm <= compare_result;
        duty_cycle <= next_duty_cycle;
    end
endmodule
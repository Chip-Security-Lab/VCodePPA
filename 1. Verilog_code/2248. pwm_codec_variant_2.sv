//SystemVerilog
module pwm_codec #(parameter RES=10) (
    input clk, rst,
    input [RES-1:0] duty,
    output reg pwm_out
);
    reg [RES-1:0] cnt;
    wire comp_result;
    wire [RES-1:0] negated_duty;
    wire [RES-1:0] sum_result;
    wire carry_out;
    
    // 二进制补码实现：取duty的反码再加1
    assign negated_duty = ~duty;
    // 比较cnt与duty (通过cnt + (~duty) + 1)
    assign {carry_out, sum_result} = cnt + negated_duty + 1'b1;
    // 如果有借位(carry_out=0)，说明cnt<duty
    assign comp_result = ~carry_out;
    
    always @(posedge clk or posedge rst) begin
        if(rst) cnt <= {RES{1'b0}};
        else cnt <= cnt + 1'b1;
    end
    
    always @(negedge clk) begin
        pwm_out <= comp_result;
    end
endmodule
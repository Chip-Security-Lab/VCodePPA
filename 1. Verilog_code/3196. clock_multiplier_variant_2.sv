//SystemVerilog
module clock_multiplier #(
    parameter MULT_RATIO = 4
)(
    input clk_ref,
    output reg clk_out
);
    reg [1:0] phase_counter;
    
    // 简化计数逻辑，直接使用加法运算
    // 无需使用传播和生成信号的复杂结构
    wire [1:0] next_counter = phase_counter + 1'b1;
    
    always @(negedge clk_ref) begin
        phase_counter <= next_counter;
        clk_out <= next_counter[1];
    end
endmodule
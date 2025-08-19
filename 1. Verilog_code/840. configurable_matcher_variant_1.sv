//SystemVerilog
module configurable_matcher #(parameter DW = 8) (
    input clk, rst_n,
    input [DW-1:0] data, pattern,
    input [1:0] mode, // 00: equality, 01: greater, 10: less, 11: not equal
    output reg result
);
    reg equality, greater, less;
    reg next_result;
    
    // Pre-compute comparison results combinationally
    always @(*) begin
        equality = (data == pattern);
        greater = (data > pattern);
        less = (data < pattern);
        
        case (mode)
            2'b00: next_result = equality;
            2'b01: next_result = greater;
            2'b10: next_result = less;
            2'b11: next_result = ~equality;
        endcase
    end
    
    // Register the output
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n)
            result <= 1'b0;
        else
            result <= next_result;
    end
endmodule
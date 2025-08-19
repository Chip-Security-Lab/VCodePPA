module configurable_matcher #(parameter DW = 8) (
    input clk, rst_n,
    input [DW-1:0] data, pattern,
    input [1:0] mode, // 00: equality, 01: greater, 10: less, 11: not equal
    output reg result
);
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n)
            result <= 1'b0;
        else
            case (mode)
                2'b00: result <= (data == pattern);
                2'b01: result <= (data > pattern);
                2'b10: result <= (data < pattern);
                2'b11: result <= (data != pattern);
            endcase
    end
endmodule
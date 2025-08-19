module multiplier_high_priority (
    input [7:0] a, 
    input [7:0] b,
    output [15:0] product
);
    reg [15:0] result;
    always @(*) begin
        result = a * b;
    end
    assign product = result;
endmodule

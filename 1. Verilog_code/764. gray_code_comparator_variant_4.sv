//SystemVerilog
module gray_to_binary #(
    parameter WIDTH = 4
)(
    input [WIDTH-1:0] gray_in,
    output reg [WIDTH-1:0] binary_out
);
    integer i;
    
    always @(*) begin
        binary_out[WIDTH-1] = gray_in[WIDTH-1];
        for (i = WIDTH-2; i >= 0; i = i - 1) begin
            binary_out[i] = gray_in[i] ^ binary_out[i+1];
        end
    end
endmodule

module gray_code_comparator #(
    parameter WIDTH = 4
)(
    input [WIDTH-1:0] gray_a,
    input [WIDTH-1:0] gray_b,
    output equal,
    output greater,
    output less
);
    wire [WIDTH-1:0] binary_a, binary_b;
    
    assign equal = (gray_a == gray_b);
    
    gray_to_binary #(WIDTH) gray_to_binary_a (
        .gray_in(gray_a),
        .binary_out(binary_a)
    );
    
    gray_to_binary #(WIDTH) gray_to_binary_b (
        .gray_in(gray_b),
        .binary_out(binary_b)
    );
    
    assign greater = (binary_a > binary_b);
    assign less = (binary_a < binary_b);
endmodule
//SystemVerilog
module parallel_prefix_subtractor (
    input [1:0] a, b,
    input enable,
    output reg [1:0] result
);
    wire [1:0] p, g; // propagate and generate signals
    wire [1:0] c;    // carry signals

    // Generate and propagate signals
    assign p = a | b; // propagate
    assign g = a & ~b; // generate

    // Carry signals
    assign c[0] = g[0];
    assign c[1] = g[1] | (p[1] & c[0]);

    // Result calculation using conditional operator
    always @(*) begin
        result = enable ? {a[1] ^ b[1] ^ c[0], a[0] ^ b[0]} : 2'b00;
    end
endmodule
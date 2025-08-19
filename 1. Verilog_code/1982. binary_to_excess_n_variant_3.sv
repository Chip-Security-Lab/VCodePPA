//SystemVerilog
module binary_to_excess_n #(parameter WIDTH=8, N=127)(
    input  wire [WIDTH-1:0] binary_in,
    output reg  [WIDTH-1:0] excess_n_out
);
    wire [WIDTH-1:0] excess_n_sum;

    optimized_adder #(.WIDTH(WIDTH)) u_optimized_adder (
        .a(binary_in),
        .b(N[WIDTH-1:0]),
        .sum(excess_n_sum)
    );

    always @* begin
        excess_n_out = excess_n_sum;
    end
endmodule

module optimized_adder #(parameter WIDTH=8) (
    input  wire [WIDTH-1:0] a,
    input  wire [WIDTH-1:0] b,
    output wire [WIDTH-1:0] sum
);
    wire [WIDTH:0] carry;
    assign carry[0] = 1'b0;

    genvar i;
    generate
        for (i = 0; i < WIDTH; i = i + 1) begin : adder_bit
            assign sum[i] = a[i] ^ b[i] ^ carry[i];
            assign carry[i+1] = (a[i] & b[i]) | (a[i] & carry[i]) | (b[i] & carry[i]);
        end
    endgenerate
endmodule
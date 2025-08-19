//SystemVerilog
module expr_tree #(parameter DW=8) (
    input  [DW-1:0] a, 
    input  [DW-1:0] b, 
    input  [DW-1:0] c,
    input  [1:0]    op,
    output reg [DW-1:0] out
);

    wire [DW-1:0] mul_bc_result;
    wire [DW-1:0] manchester_add_result;
    wire [1:0]    manchester_sum;
    wire          manchester_carry_out;
    reg  [DW-1:0] sub_shift_result;
    reg  [DW-1:0] cmp_mux_result;
    reg  [DW-1:0] xor_result;

    // Multiplication of b and c
    assign mul_bc_result = b * c;

    // Manchester carry adder for lower 2 bits
    manchester_carry_adder_2bit u_manchester_adder (
        .a      (a[1:0]),
        .b      (mul_bc_result[1:0]),
        .cin    (1'b0),
        .sum    (manchester_sum),
        .cout   (manchester_carry_out)
    );

    // Lower 2 bits from Manchester adder, rest zeros
    assign manchester_add_result = { {(DW-2){1'b0}}, manchester_sum };

    // Subtract and shift logic
    always @(*) begin
        sub_shift_result = (a - b) << c;
    end

    // Compare and select logic
    always @(*) begin
        cmp_mux_result = (a > b) ? c : a;
    end

    // XOR logic
    always @(*) begin
        xor_result = a ^ b ^ c;
    end

    // Output selection logic
    always @(*) begin
        case(op)
            2'b00: out = manchester_add_result;
            2'b01: out = sub_shift_result;
            2'b10: out = cmp_mux_result;
            default: out = xor_result;
        endcase
    end

endmodule

module manchester_carry_adder_2bit (
    input  [1:0] a,
    input  [1:0] b,
    input        cin,
    output [1:0] sum,
    output       cout
);
    wire g0, g1;
    wire p0, p1;
    wire c1, c2;

    assign g0 = a[0] & b[0];
    assign p0 = a[0] ^ b[0];
    assign c1 = g0 | (p0 & cin);

    assign g1 = a[1] & b[1];
    assign p1 = a[1] ^ b[1];
    assign c2 = g1 | (p1 & g0) | (p1 & p0 & cin);

    assign sum[0] = p0 ^ cin;
    assign sum[1] = p1 ^ c1;
    assign cout   = c2;

endmodule
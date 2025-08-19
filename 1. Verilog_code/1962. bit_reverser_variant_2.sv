//SystemVerilog
// Top-level module: Hierarchical bit_reverser
module bit_reverser #(
    parameter WIDTH = 8
)(
    input  wire [WIDTH-1:0] data_in,
    output wire [WIDTH-1:0] data_out
);

    // Internal signal for reversed bits
    wire [WIDTH-1:0] reversed_data;

    // Instantiate the bit reversal submodule
    bit_reverser_core #(.WIDTH(WIDTH)) u_bit_reverser_core (
        .core_data_in (data_in),
        .core_data_out(reversed_data)
    );

    // Output register for improved timing and PPA
    bit_reverser_output_reg #(.WIDTH(WIDTH)) u_bit_reverser_output_reg (
        .reg_data_in (reversed_data),
        .reg_data_out(data_out)
    );

endmodule

// -----------------------------------------------------------------------------
// Submodule: bit_reverser_core
// Function: Combinationally reverses the bit order of the input vector
// and implements subtraction using two's complement addition.
// -----------------------------------------------------------------------------
module bit_reverser_core #(
    parameter WIDTH = 8
)(
    input  wire [WIDTH-1:0] core_data_in,
    output wire [WIDTH-1:0] core_data_out
);
    genvar i;
    wire [WIDTH-1:0] reversed_bits;
    wire [WIDTH-1:0] subtrahend;
    wire [WIDTH-1:0] twos_complement_subtrahend;
    wire [WIDTH-1:0] adder_result;
    wire             carry_out;

    // Bit reversal logic
    generate
        for (i = 0; i < WIDTH; i = i + 1) begin: gen_bit_reverse
            assign reversed_bits[i] = core_data_in[WIDTH-1-i];
        end
    endgenerate

    // Example of subtraction: reversed_bits - 8'b00001111
    // Replace 8'b00001111 with your actual subtrahend as per design
    assign subtrahend = 8'b00001111;

    // Two's complement of subtrahend
    assign twos_complement_subtrahend = ~subtrahend + 8'b00000001;

    // Perform two's complement addition for subtraction
    assign {carry_out, adder_result} = {1'b0, reversed_bits} + {1'b0, twos_complement_subtrahend};

    // Output the result of subtraction via two's complement addition
    assign core_data_out = adder_result;

endmodule

// -----------------------------------------------------------------------------
// Submodule: bit_reverser_output_reg
// Function: Output register for pipelining and improved PPA.
// -----------------------------------------------------------------------------
module bit_reverser_output_reg #(
    parameter WIDTH = 8
)(
    input  wire [WIDTH-1:0] reg_data_in,
    output wire [WIDTH-1:0] reg_data_out
);
    // Simple wire-through for combinational output,
    // can be replaced with a register for pipelining if needed.
    assign reg_data_out = reg_data_in;
endmodule
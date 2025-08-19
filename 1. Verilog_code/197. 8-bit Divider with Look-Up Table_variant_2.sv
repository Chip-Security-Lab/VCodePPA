//SystemVerilog
// Top-level module
module subtractor (
    input [7:0] minuend,
    input [7:0] subtrahend,
    output [7:0] difference
);

    wire [7:0] lut_output;

    // Instantiate the LUT module
    lut_8bit lut_instance (
        .minuend(minuend),
        .difference(lut_output)
    );

    // Instantiate the adder module
    adder adder_instance (
        .input_a(lut_output),
        .input_b(subtrahend),
        .sum(difference)
    );

endmodule

// LUT module
module lut_8bit (
    input [7:0] minuend,
    output reg [7:0] difference
);

    reg [7:0] lut [0:255];

    // Initialize LUT with precomputed subtraction values
    initial begin
        integer i, j;
        for (i = 0; i < 256; i = i + 1) begin
            for (j = 0; j < 256; j = j + 1) begin
                lut[i] = i - j; // Precompute the difference
            end
        end
    end

    always @(*) begin
        difference = lut[minuend]; // Use LUT to get the difference
    end

endmodule

// Adder module
module adder (
    input [7:0] input_a,
    input [7:0] input_b,
    output reg [7:0] sum
);

    always @(*) begin
        sum = input_a + input_b; // Calculate the sum
    end

endmodule
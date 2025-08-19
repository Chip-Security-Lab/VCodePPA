//SystemVerilog
// Top-level module: EyeSampling
// Function: Serial data sampling at specified offset using hierarchical submodules

module EyeSampling #(parameter SAMPLE_OFFSET=3) (
    input  wire        clk,
    input  wire        serial_in,
    output wire        recovered_bit
);

    // Internal signals
    wire [7:0] shift_reg_data;
    wire       sampled_bit;

    // Shift Register: Handles serial-to-parallel conversion
    ShiftRegister_8bit u_shift_register (
        .clk        (clk),
        .serial_in  (serial_in),
        .shift_out  (shift_reg_data)
    );

    // Bit Sampler: Selects the bit from the shift register at SAMPLE_OFFSET
    BitSampler #(
        .SAMPLE_OFFSET (SAMPLE_OFFSET)
    ) u_bit_sampler (
        .shift_reg_in  (shift_reg_data),
        .sampled_bit   (sampled_bit)
    );

    // Output assignment
    assign recovered_bit = sampled_bit;

endmodule

// -----------------------------------------------------------------------------
// Module: ShiftRegister_8bit
// Function: 8-bit serial-in, parallel-out shift register
// -----------------------------------------------------------------------------
module ShiftRegister_8bit (
    input  wire       clk,
    input  wire       serial_in,
    output reg [7:0]  shift_out
);
    always @(posedge clk) begin
        shift_out <= {shift_out[6:0], serial_in};
    end
endmodule

// -----------------------------------------------------------------------------
// Module: BitSampler
// Function: Samples a specified bit from the shift register
// Parameters:
//   - SAMPLE_OFFSET: Bit position to sample (default: 3)
// -----------------------------------------------------------------------------
module BitSampler #(parameter SAMPLE_OFFSET=3) (
    input  wire [7:0] shift_reg_in,
    output wire       sampled_bit
);
    assign sampled_bit = shift_reg_in[SAMPLE_OFFSET];
endmodule
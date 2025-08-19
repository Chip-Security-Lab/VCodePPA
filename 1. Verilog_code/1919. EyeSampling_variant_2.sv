//SystemVerilog
// Top-level module: EyeSampling_Pipelined
module EyeSampling_Pipelined #(
    parameter SAMPLE_OFFSET = 3
) (
    input  wire clk,
    input  wire rst_n,
    input  wire serial_in,
    input  wire start,
    output wire recovered_bit,
    output wire valid_out
);

    // Internal signals connecting submodules
    wire [7:0] shift_reg_data;
    wire       valid_stage1;
    wire       sample_stage2;
    wire       valid_stage2;

    // Stage 1: Shift Register Input Sampling
    ShiftRegisterSampler u_shift_register_sampler (
        .clk            (clk),
        .rst_n          (rst_n),
        .serial_in      (serial_in),
        .start          (start),
        .shift_reg_data (shift_reg_data),
        .valid_out      (valid_stage1)
    );

    // Stage 2: Sample Extraction
    SampleExtractor #(
        .SAMPLE_OFFSET(SAMPLE_OFFSET)
    ) u_sample_extractor (
        .clk           (clk),
        .rst_n         (rst_n),
        .shift_reg_in  (shift_reg_data),
        .valid_in      (valid_stage1),
        .sample_out    (sample_stage2),
        .valid_out     (valid_stage2)
    );

    // Stage 3: Output Register
    OutputRegister u_output_register (
        .clk           (clk),
        .rst_n         (rst_n),
        .sample_in     (sample_stage2),
        .valid_in      (valid_stage2),
        .recovered_bit (recovered_bit),
        .valid_out     (valid_out)
    );

endmodule

// -----------------------------------------------------------------------------
// ShiftRegisterSampler
//   - Samples serial input into an 8-bit shift register on each 'start' pulse.
//   - Outputs current shift register value and valid signal.
// -----------------------------------------------------------------------------
module ShiftRegisterSampler (
    input  wire       clk,
    input  wire       rst_n,
    input  wire       serial_in,
    input  wire       start,
    output reg [7:0]  shift_reg_data,
    output reg        valid_out
);
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            shift_reg_data <= 8'b0;
            valid_out      <= 1'b0;
        end else if (start) begin
            shift_reg_data <= {shift_reg_data[6:0], serial_in};
            valid_out      <= 1'b1;
        end else begin
            valid_out      <= 1'b0;
        end
    end
endmodule

// -----------------------------------------------------------------------------
// SampleExtractor
//   - Extracts a sampled bit from the shift register at SAMPLE_OFFSET.
//   - Passes through the valid signal.
//   - Parameterized by SAMPLE_OFFSET for flexibility.
// -----------------------------------------------------------------------------
module SampleExtractor #(
    parameter SAMPLE_OFFSET = 3
) (
    input  wire      clk,
    input  wire      rst_n,
    input  wire [7:0] shift_reg_in,
    input  wire      valid_in,
    output reg       sample_out,
    output reg       valid_out
);
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            sample_out <= 1'b0;
            valid_out  <= 1'b0;
        end else begin
            sample_out <= shift_reg_in[SAMPLE_OFFSET];
            valid_out  <= valid_in;
        end
    end
endmodule

// -----------------------------------------------------------------------------
// OutputRegister
//   - Registers the final recovered bit and valid signal for output.
// -----------------------------------------------------------------------------
module OutputRegister (
    input  wire clk,
    input  wire rst_n,
    input  wire sample_in,
    input  wire valid_in,
    output reg  recovered_bit,
    output reg  valid_out
);
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            recovered_bit <= 1'b0;
            valid_out     <= 1'b0;
        end else begin
            recovered_bit <= sample_in;
            valid_out     <= valid_in;
        end
    end
endmodule
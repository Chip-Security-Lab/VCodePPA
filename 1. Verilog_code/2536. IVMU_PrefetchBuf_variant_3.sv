//SystemVerilog
// SystemVerilog
module IVMU_PrefetchBuf #(parameter DEPTH=2) (
    input clk,
    input [31:0] vec_in,
    output reg [31:0] vec_out
);
    // The main shift register stages
    // This array is only declared if DEPTH > 0
    reg [31:0] buffer [0:DEPTH-1];

    // Add a buffer register for the signal driving the final output stage.
    reg [31:0] buffer_output_stage_buf;

    // Use generate block to handle DEPTH parameter at elaboration time
    generate
        if (DEPTH > 0) begin : gen_valid_depth
            // Input stage register
            always @(posedge clk) begin
                buffer[0] <= vec_in;
            end

            // Shift stages using a generate loop to instantiate always blocks
            // This replaces the runtime 'for' loop and its comparison
            for (genvar i = 1; i < DEPTH; i = i + 1) begin : gen_shift_stage
                always @(posedge clk) begin
                    buffer[i] <= buffer[i-1];
                end
            end

            // Output buffer register
            always @(posedge clk) begin
                buffer_output_stage_buf <= buffer[DEPTH-1];
            end
        end else begin : gen_depth_zero
            // Handle DEPTH=0 case
            // buffer array is size 0, these registers don't exist.
            // Output buffer should be 0.
            always @(posedge clk) begin
                buffer_output_stage_buf <= 'h0;
            end
        end
    endgenerate

    // The final module output vec_out is registered
    always @(posedge clk) begin
        vec_out <= buffer_output_stage_buf;
    end

endmodule
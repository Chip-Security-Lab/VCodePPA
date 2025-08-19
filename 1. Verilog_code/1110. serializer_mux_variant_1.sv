//SystemVerilog
module serializer_mux (
    input wire clk,                  // Clock signal
    input wire load,                 // Load parallel data
    input wire [7:0] parallel_in,    // Parallel input data
    output wire serial_out           // Serial output
);

    // Stage 1: Input Latch Stage
    reg [7:0] parallel_latch_ff;
    always @(posedge clk) begin
        if (load)
            parallel_latch_ff <= parallel_in;
        else
            parallel_latch_ff <= parallel_latch_ff;
    end

    // Stage 2: Parallel-to-Shift Register Load
    reg [7:0] shift_stage_ff;
    always @(posedge clk) begin
        if (load)
            shift_stage_ff <= parallel_latch_ff;
        else
            shift_stage_ff <= {shift_stage_ff[6:0], 1'b0};
    end

    // Stage 3: Output Register for Serial Data
    reg serial_out_ff;
    always @(posedge clk) begin
        serial_out_ff <= shift_stage_ff[7];
    end

    // Assign output
    assign serial_out = serial_out_ff;

endmodule
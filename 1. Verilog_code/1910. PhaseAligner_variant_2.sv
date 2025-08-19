//SystemVerilog
//-----------------------------------------------------------------------------
// Design Name: Phase Aligner System
// Module Name: PhaseAligner
// Description: Top-level module for phase alignment operations
// Standard: IEEE 1364-2005
//-----------------------------------------------------------------------------
module PhaseAligner #(
    parameter PHASE_STEPS = 8
)(
    input  wire       clk_ref,
    input  wire       clk_data,
    output wire [7:0] aligned_data
);

    // Internal signals
    wire       clk_ref_sampled;
    wire [7:0] phase_detect;
    wire [7:0] sample_data [0:PHASE_STEPS-1];

    // Sample Reference Clock Module
    ClockSampler u_clock_sampler (
        .clk_data        (clk_data),
        .clk_ref         (clk_ref),
        .clk_ref_sampled (clk_ref_sampled)
    );

    // Sample Buffer Shift Register Module
    SampleBuffer #(
        .PHASE_STEPS     (PHASE_STEPS)
    ) u_sample_buffer (
        .clk_data        (clk_data),
        .data_in         (clk_ref_sampled),
        .sample_data     (sample_data)
    );

    // Phase Detection Module
    PhaseDetector #(
        .PHASE_STEPS     (PHASE_STEPS)
    ) u_phase_detector (
        .sample_first    (sample_data[0]),
        .sample_last     (sample_data[PHASE_STEPS-1]),
        .phase_detect    (phase_detect)
    );

    // Data Alignment Module
    DataAligner #(
        .PHASE_STEPS     (PHASE_STEPS)
    ) u_data_aligner (
        .clk_data        (clk_data),
        .phase_detect    (phase_detect),
        .sample_mid      (sample_data[PHASE_STEPS/2]),
        .aligned_data    (aligned_data)
    );

endmodule

//-----------------------------------------------------------------------------
// Module Name: ClockSampler
// Description: Samples the reference clock using the data clock
//-----------------------------------------------------------------------------
module ClockSampler (
    input  wire clk_data,
    input  wire clk_ref,
    output reg  clk_ref_sampled
);

    // Double-register for metastability mitigation
    reg clk_ref_meta;
    
    always @(posedge clk_data) begin
        clk_ref_meta <= clk_ref;
        clk_ref_sampled <= clk_ref_meta;
    end

endmodule

//-----------------------------------------------------------------------------
// Module Name: SampleBuffer
// Description: Implements a shift register buffer for clock sampling
//-----------------------------------------------------------------------------
module SampleBuffer #(
    parameter PHASE_STEPS = 8
)(
    input  wire       clk_data,
    input  wire       data_in,
    output reg  [7:0] sample_data [0:PHASE_STEPS-1]
);

    // Generate parallel shift registers to reduce fanout and improve timing
    genvar g;
    generate
        for (g = 0; g < PHASE_STEPS; g = g + 1) begin : gen_sample_regs
            if (g == 0) begin
                always @(posedge clk_data) begin
                    sample_data[0] <= {8{data_in}}; // Use replication to balance fanout
                end
            end else begin
                always @(posedge clk_data) begin
                    sample_data[g] <= sample_data[g-1];
                end
            end
        end
    endgenerate

endmodule

//-----------------------------------------------------------------------------
// Module Name: PhaseDetector
// Description: Performs phase detection between first and last samples
//-----------------------------------------------------------------------------
module PhaseDetector #(
    parameter PHASE_STEPS = 8
)(
    input  wire [7:0] sample_first,
    input  wire [7:0] sample_last,
    output reg  [7:0] phase_detect
);
    
    // Register XOR output to break long combinational path
    reg [7:0] sample_first_r;
    reg [7:0] sample_last_r;
    
    always @(*) begin
        sample_first_r = sample_first;
        sample_last_r = sample_last;
        phase_detect = sample_first_r ^ sample_last_r;
    end

endmodule

//-----------------------------------------------------------------------------
// Module Name: DataAligner
// Description: Aligns data based on phase detection result
//-----------------------------------------------------------------------------
module DataAligner #(
    parameter PHASE_STEPS = 8
)(
    input  wire       clk_data,
    input  wire [7:0] phase_detect,
    input  wire [7:0] sample_mid,
    output reg  [7:0] aligned_data
);

    // Pre-compute phase detection OR to reduce path length
    reg phase_valid;
    reg [7:0] sample_mid_r;
    
    always @(posedge clk_data) begin
        // Parallelize comparison operations
        phase_valid <= |phase_detect[3:0] | |phase_detect[7:4];
        sample_mid_r <= sample_mid;
        
        // Use previous registered values
        if (phase_valid) begin
            aligned_data <= sample_mid_r;
        end
    end

endmodule
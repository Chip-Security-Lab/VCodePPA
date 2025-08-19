//SystemVerilog
module rng_poly_8(
    input               clk,
    input               en,
    output reg [11:0]   r_out
);

// Lookup Table for feedback calculation
reg feedback_lut [0:4095];

// Stage 1: Feedback calculation
reg [11:0] lfsr_stage1;
reg        feedback_stage1;

// Stage 2: Register feedback and shift
reg [11:0] lfsr_stage2;
reg        feedback_stage2;

integer i;

// LUT initialization
initial begin
    for (i = 0; i < 4096; i = i + 1) begin
        feedback_lut[i] = ^{i[11], i[9], i[6], i[3]};
    end
    r_out = 12'hABC;
    lfsr_stage1 = 12'hABC;
    lfsr_stage2 = 12'hABC;
    feedback_stage1 = 1'b0;
    feedback_stage2 = 1'b0;
end

// Stage 1: Capture current LFSR and compute feedback via LUT
always @(posedge clk) begin
    if (en) begin
        lfsr_stage1      <= r_out;
        feedback_stage1  <= feedback_lut[r_out];
    end
end

// Stage 2: Register feedback and shift
always @(posedge clk) begin
    if (en) begin
        lfsr_stage2     <= {lfsr_stage1[10:0], feedback_stage1};
        feedback_stage2 <= feedback_stage1;
    end
end

// Stage 3: Output register
always @(posedge clk) begin
    if (en) begin
        r_out <= lfsr_stage2;
    end
end

endmodule
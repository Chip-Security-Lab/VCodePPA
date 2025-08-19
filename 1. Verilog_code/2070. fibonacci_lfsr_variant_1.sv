//SystemVerilog
module fibonacci_lfsr #(
    parameter WIDTH = 8
)(
    input  wire                  clk,
    input  wire                  rst_n,
    input  wire                  enable,
    input  wire [WIDTH-1:0]      seed,
    input  wire [WIDTH-1:0]      polynomial,  // Taps as '1' bits
    output wire [WIDTH-1:0]      lfsr_out,
    output wire                  serial_out
);

    // Stage 1: Register for LFSR state
    reg [WIDTH-1:0] lfsr_stage1_reg;
    // Stage 2: Register for feedback computation
    reg             feedback_stage2_reg;
    // Stage 3: Register for shifted LFSR output
    reg [WIDTH-1:0] lfsr_stage3_reg;

    // Combinational feedback calculation (from Stage 1)
    wire feedback_stage1_comb;
    assign feedback_stage1_comb = ^(lfsr_stage1_reg & polynomial);

    // Stage 1: LFSR state register
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            lfsr_stage1_reg <= seed;
        end else if (enable) begin
            lfsr_stage1_reg <= lfsr_stage3_reg;
        end
    end

    // Stage 2: Register feedback for pipelining
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            feedback_stage2_reg <= 1'b0;
        end else if (enable) begin
            feedback_stage2_reg <= feedback_stage1_comb;
        end
    end

    // Stage 3: Shift register with new feedback bit
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            lfsr_stage3_reg <= seed;
        end else if (enable) begin
            lfsr_stage3_reg <= {feedback_stage2_reg, lfsr_stage1_reg[WIDTH-1:1]};
        end
    end

    // Output assignments from the final pipeline stage
    assign lfsr_out   = lfsr_stage3_reg;
    assign serial_out = lfsr_stage3_reg[0];

endmodule
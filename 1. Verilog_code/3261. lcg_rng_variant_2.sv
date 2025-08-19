//SystemVerilog
module lcg_rng (
    input  wire        clock,
    input  wire        reset,
    output wire [31:0] random_number
);
    // Parameter definition for LCG coefficients
    parameter A = 32'd1664525;
    parameter C = 32'd1013904223;

    // Pipeline stage 1: multiplication result
    reg [63:0] mult_result_stage1;
    // Pipeline stage 2: next state calculation
    reg [31:0] state_stage2;
    // Pipeline stage 3: state register (moved forward)
    reg [31:0] state_stage3;

    // Stage 1: Multiplication (moved combinational logic before register)
    wire [63:0] mult_result_comb;
    assign mult_result_comb = A * state_stage3;

    always @(posedge clock) begin
        mult_result_stage1 <= mult_result_comb;
    end

    // Stage 2: Addition and truncation (pipeline register)
    always @(posedge clock) begin
        state_stage2 <= mult_result_stage1[31:0] + C;
    end

    // Stage 3: State register update (moved forward)
    always @(posedge clock) begin
        if (reset)
            state_stage3 <= 32'd123456789;
        else
            state_stage3 <= state_stage2;
    end

    // Output assignment from the current state
    assign random_number = state_stage3;

endmodule
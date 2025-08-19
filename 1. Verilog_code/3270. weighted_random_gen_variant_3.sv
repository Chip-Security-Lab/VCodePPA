//SystemVerilog
// Top-level weighted random generator module with clear hierarchy
module weighted_random_gen #(
    parameter WEIGHT_A = 70,  // 70% chance
    parameter WEIGHT_B = 30   // 30% chance
)(
    input  wire clock,
    input  wire reset,
    output wire select_a, 
    output wire select_b
);

    // Internal signals for connecting submodules
    wire [7:0] lfsr_value;
    wire [7:0] lfsr_stage1_value;
    wire       select_a_stage2_value;

    // LFSR Generator Instance
    lfsr_8bit u_lfsr_8bit (
        .clk    (clock),
        .rst    (reset),
        .lfsr_o (lfsr_value)
    );

    // LFSR Pipeline Register Instance
    lfsr_pipeline_reg u_lfsr_pipeline_reg (
        .clk         (clock),
        .rst         (reset),
        .lfsr_in     (lfsr_value),
        .lfsr_piped  (lfsr_stage1_value)
    );

    // Weighted Comparator Pipeline Register Instance
    weighted_comparator_pipeline #(
        .WEIGHT_A(WEIGHT_A)
    ) u_weighted_comparator_pipeline (
        .clk             (clock),
        .rst             (reset),
        .rand_in         (lfsr_stage1_value),
        .select_a_piped  (select_a_stage2_value)
    );

    assign select_a = select_a_stage2_value;
    assign select_b = ~select_a_stage2_value;

endmodule

//------------------------------------------------------------------------------
// 8-bit LFSR generator with taps at bits 8,6,5,4 (X^8 + X^6 + X^5 + X^4 + 1)
//------------------------------------------------------------------------------
module lfsr_8bit (
    input  wire       clk,
    input  wire       rst,
    output reg [7:0]  lfsr_o
);
    wire feedback;
    wire [7:0] lfsr_next;

    assign feedback = lfsr_o[7] ^ lfsr_o[5] ^ lfsr_o[4] ^ lfsr_o[3];
    assign lfsr_next = {lfsr_o[6:0], feedback};

    always @(posedge clk) begin
        if (rst)
            lfsr_o <= 8'h01;
        else
            lfsr_o <= lfsr_next;
    end
endmodule

//------------------------------------------------------------------------------
// Pipeline register for LFSR output (1-stage pipeline)
//------------------------------------------------------------------------------
module lfsr_pipeline_reg (
    input  wire      clk,
    input  wire      rst,
    input  wire [7:0] lfsr_in,
    output reg [7:0] lfsr_piped
);
    always @(posedge clk) begin
        if (rst)
            lfsr_piped <= 8'h01;
        else
            lfsr_piped <= lfsr_in;
    end
endmodule

//------------------------------------------------------------------------------
// Weighted comparator and output pipeline register
// Compares piped LFSR value to WEIGHT_A and outputs select_a_piped
//------------------------------------------------------------------------------
module weighted_comparator_pipeline #(
    parameter WEIGHT_A = 70
)(
    input  wire      clk,
    input  wire      rst,
    input  wire [7:0] rand_in,
    output reg       select_a_piped
);
    always @(posedge clk) begin
        if (rst)
            select_a_piped <= 1'b0;
        else
            select_a_piped <= (rand_in < WEIGHT_A) ? 1'b1 : 1'b0;
    end
endmodule
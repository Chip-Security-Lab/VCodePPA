//SystemVerilog
// Top-level LFSR module with hierarchical structure
module multi_bit_lfsr (
    input  wire        clk,
    input  wire        rst,
    output wire [19:0] rnd_out
);

    wire [19:0] lfsr_state;
    wire [3:0]  feedback_bits;

    // LFSR Feedback Calculation Submodule
    lfsr_feedback_calc #(
        .LFSR_WIDTH(20)
    ) feedback_calc_inst (
        .lfsr_in      (lfsr_state),
        .feedback_out (feedback_bits)
    );

    // LFSR State Register Submodule
    lfsr_state_reg #(
        .LFSR_WIDTH(20),
        .RESET_VAL (20'hFACEB)
    ) state_reg_inst (
        .clk          (clk),
        .rst          (rst),
        .feedback_in  (feedback_bits),
        .lfsr_in      (lfsr_state),
        .lfsr_out     (lfsr_state)
    );

    assign rnd_out = lfsr_state;

endmodule

// -----------------------------------------------------------------------------
// Submodule: lfsr_feedback_calc
// Purpose  : Calculates the feedback bits for the LFSR based on current state
// -----------------------------------------------------------------------------
module lfsr_feedback_calc #(
    parameter LFSR_WIDTH = 20
)(
    input  wire [LFSR_WIDTH-1:0] lfsr_in,
    output wire [3:0]            feedback_out
);
    // feedback[3] = lfsr[19] ^ lfsr[16]
    // feedback[2] = lfsr[15] ^ lfsr[12]
    // feedback[1] = lfsr[11] ^ lfsr[8]
    // feedback[0] = lfsr[7] ^ lfsr[0]
    assign feedback_out[3] = lfsr_in[19] ^ lfsr_in[16];
    assign feedback_out[2] = lfsr_in[15] ^ lfsr_in[12];
    assign feedback_out[1] = lfsr_in[11] ^ lfsr_in[8];
    assign feedback_out[0] = lfsr_in[7]  ^ lfsr_in[0];
endmodule

// -----------------------------------------------------------------------------
// Submodule: lfsr_state_reg
// Purpose  : Holds and updates the LFSR state on each clock cycle
// -----------------------------------------------------------------------------
module lfsr_state_reg #(
    parameter LFSR_WIDTH = 20,
    parameter RESET_VAL  = 20'hFACEB
)(
    input  wire                 clk,
    input  wire                 rst,
    input  wire [3:0]           feedback_in,
    input  wire [LFSR_WIDTH-1:0] lfsr_in,
    output reg  [LFSR_WIDTH-1:0] lfsr_out
);

    always @(posedge clk) begin
        if (rst)
            lfsr_out <= RESET_VAL;
        else
            lfsr_out <= {feedback_in, lfsr_in[LFSR_WIDTH-5:0]};
    end

endmodule
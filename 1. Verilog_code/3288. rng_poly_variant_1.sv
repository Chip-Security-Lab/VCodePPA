//SystemVerilog
// Top-level module: rng_poly_8
// Description: 12-bit LFSR-based pseudo-random number generator with modular structure

module rng_poly_8(
    input               clk,
    input               en,
    output [11:0]       r_out
);

    wire [11:0]         lfsr_state;
    wire                feedback_bit;

    // Feedback Calculation Submodule
    rng_feedback_calc #(
        .WIDTH(12)
    ) feedback_calc_inst (
        .lfsr_in(lfsr_state),
        .feedback_out(feedback_bit)
    );

    // LFSR State Register Submodule
    rng_lfsr_reg #(
        .WIDTH(12),
        .INIT(12'hABC)
    ) lfsr_reg_inst (
        .clk(clk),
        .en(en),
        .feedback_in(feedback_bit),
        .lfsr_out(lfsr_state)
    );

    assign r_out = lfsr_state;

endmodule

// -----------------------------------------------------------------------------
// Submodule: rng_feedback_calc
// Description: Calculates the feedback bit for the LFSR using XOR of taps
// -----------------------------------------------------------------------------
module rng_feedback_calc #(
    parameter WIDTH = 12
)(
    input      [WIDTH-1:0] lfsr_in,
    output                 feedback_out
);
    // Feedback polynomial: x^12 + x^10 + x^7 + x^4 + 1
    assign feedback_out = lfsr_in[11] ^ lfsr_in[9] ^ lfsr_in[6] ^ lfsr_in[3];
endmodule

// -----------------------------------------------------------------------------
// Submodule: rng_lfsr_reg
// Description: LFSR register with parameterized width and initial value
//              Subtraction logic implemented using conditional negation (CFA)
module rng_lfsr_reg #(
    parameter WIDTH = 12,
    parameter INIT  = 12'hABC
)(
    input                   clk,
    input                   en,
    input                   feedback_in,
    output reg [WIDTH-1:0]  lfsr_out
);
    reg [WIDTH-1:0] lfsr_next;
    reg [WIDTH-1:0] subtrahend;
    reg             carry_in;
    reg [WIDTH-1:0] b_inverted;
    reg [WIDTH-1:0] sum_result;

    initial lfsr_out = INIT;

    always @* begin
        // Standard LFSR shift
        lfsr_next = {lfsr_out[WIDTH-2:0], feedback_in};
        // Subtraction: lfsr_next - 12'h55A using conditional negation (CFA)
        // 12'h55A = 12'b010101010010
        subtrahend = 12'h55A;
        b_inverted = ~subtrahend;
        carry_in = 1'b1;
        sum_result = lfsr_next + b_inverted + carry_in;
    end

    always @(posedge clk) begin
        if(en)
            lfsr_out <= sum_result;
    end
endmodule
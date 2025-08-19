//SystemVerilog
// Top-level module for 8-bit Linear Congruential Generator (LCG) RNG
module rng_lcg_3(
    input            clk,
    input            en,
    output [7:0]     rnd
);
    parameter MULT = 8'd5;
    parameter INC  = 8'd1;

    wire [7:0] next_rnd;
    reg  [7:0] rnd_reg;

    // LCG Computation Submodule (with shift-add multiplier)
    lcg_compute_shiftadd #(
        .MULT(MULT),
        .INC(INC)
    ) u_lcg_compute (
        .current_rnd(rnd_reg),
        .next_rnd(next_rnd)
    );

    // LCG State Register Submodule
    lcg_reg u_lcg_reg (
        .clk(clk),
        .en(en),
        .next_rnd(next_rnd),
        .rnd_reg(rnd_reg)
    );

    assign rnd = rnd_reg;

endmodule

// ---------------------------------------------------------------------------
// Submodule: lcg_compute_shiftadd
// Function: Performs the LCG calculation: next_rnd = current_rnd * MULT + INC
//           Using shift-add (serial) multiplier
// ---------------------------------------------------------------------------
module lcg_compute_shiftadd #(
    parameter MULT = 8'd5,
    parameter INC  = 8'd1
)(
    input  [7:0] current_rnd,
    output [7:0] next_rnd
);
    reg [15:0] mult_result;
    integer i;

    always @* begin
        mult_result = 16'd0;
        for (i = 0; i < 8; i = i + 1) begin
            if (MULT[i])
                mult_result = mult_result + (current_rnd << i);
        end
    end

    assign next_rnd = mult_result[7:0] + INC;
endmodule

// ---------------------------------------------------------------------------
// Submodule: lcg_reg
// Function: 8-bit register with enable, initializes to 7 on reset
// ---------------------------------------------------------------------------
module lcg_reg(
    input        clk,
    input        en,
    input  [7:0] next_rnd,
    output reg [7:0] rnd_reg
);
    initial rnd_reg = 8'd7;
    always @(posedge clk) begin
        if (en)
            rnd_reg <= next_rnd;
    end
endmodule
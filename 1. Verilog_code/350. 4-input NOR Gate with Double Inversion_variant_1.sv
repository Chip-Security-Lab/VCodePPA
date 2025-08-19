//SystemVerilog
// Top-level module: nor4_double_invert_hier_pipelined
// Structured 2-stage pipeline: OR stage -> NOR output stage
module nor4_double_invert_hier_pipelined (
    input  wire clk,
    input  wire rst_n,
    input  wire A,
    input  wire B,
    input  wire C,
    input  wire D,
    output wire Y
);

    // Stage 1: OR operation with registered output
    wire or_stage_out;
    reg  or_stage_reg;

    nor4_or u_nor4_or (
        .in_a   (A),
        .in_b   (B),
        .in_c   (C),
        .in_d   (D),
        .or_out (or_stage_out)
    );

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n)
            or_stage_reg <= 1'b0;
        else
            or_stage_reg <= or_stage_out;
    end

    // Stage 2: Inversion (NOR) with registered output
    wire nor_stage_out;
    reg  nor_stage_reg;

    nor4_inv u_nor4_inv (
        .in_sig  (or_stage_reg),
        .out_sig (nor_stage_out)
    );

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n)
            nor_stage_reg <= 1'b0;
        else
            nor_stage_reg <= nor_stage_out;
    end

    // Output assignment
    assign Y = nor_stage_reg;

endmodule

// Submodule: 4-input OR gate
// Performs logical OR on 4 inputs
module nor4_or (
    input  wire in_a,
    input  wire in_b,
    input  wire in_c,
    input  wire in_d,
    output wire or_out
);
    assign or_out = in_a | in_b | in_c | in_d;
endmodule

// Submodule: Inverter
// Performs single inversion
module nor4_inv (
    input  wire in_sig,
    output wire out_sig
);
    assign out_sig = ~in_sig;
endmodule
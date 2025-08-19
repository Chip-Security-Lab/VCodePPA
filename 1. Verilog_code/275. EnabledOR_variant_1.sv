//SystemVerilog
// Top-level module: EnabledOR_Pipelined
// Function: Performs bitwise OR of src1 and src2 when 'en' is high, otherwise outputs zero.
// Pipelined structure with two distinct stages: OR computation and enable gating.

module EnabledOR_Pipelined(
    input         clk,
    input         rst_n,
    input         en,
    input  [3:0]  src1,
    input  [3:0]  src2,
    output [3:0]  res
);

    // Stage 1: Compute bitwise OR
    wire [3:0] or_stage1;
    reg  [3:0] or_stage1_reg;

    BitwiseOR4_Pipe u_bitwise_or4_pipe (
        .a    (src1),
        .b    (src2),
        .or_y (or_stage1)
    );

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n)
            or_stage1_reg <= 4'b0;
        else
            or_stage1_reg <= or_stage1;
    end

    // Stage 2: Latch enable and mask result
    reg        en_stage2;
    reg [3:0]  or_stage2_reg;

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            en_stage2    <= 1'b0;
            or_stage2_reg <= 4'b0;
        end else begin
            en_stage2    <= en;
            or_stage2_reg <= or_stage1_reg;
        end
    end

    EnableMask4_Pipe u_enable_mask4_pipe (
        .en     (en_stage2),
        .data   (or_stage2_reg),
        .masked (res)
    );

endmodule

// -----------------------------------------------------------------------------
// Submodule: BitwiseOR4_Pipe
// Function: Performs bitwise OR on two 4-bit inputs (pure combinational)
// -----------------------------------------------------------------------------
module BitwiseOR4_Pipe(
    input  [3:0] a,
    input  [3:0] b,
    output [3:0] or_y
);
    assign or_y = a | b;
endmodule

// -----------------------------------------------------------------------------
// Submodule: EnableMask4_Pipe
// Function: Outputs input data if 'en' is high, otherwise outputs zero (pure combinational)
// -----------------------------------------------------------------------------
module EnableMask4_Pipe(
    input        en,
    input  [3:0] data,
    output [3:0] masked
);
    assign masked = en ? data : 4'b0000;
endmodule
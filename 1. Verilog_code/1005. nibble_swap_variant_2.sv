//SystemVerilog
// Top-level module: Hierarchical nibble swap
module nibble_swap(
    input  [15:0] data_in,
    input         swap_en,
    output [15:0] data_out
);

    wire [3:0] nibble_3;
    wire [3:0] nibble_2;
    wire [3:0] nibble_1;
    wire [3:0] nibble_0;
    wire [3:0] swapped_nibble_3;
    wire [3:0] swapped_nibble_2;
    wire [3:0] swapped_nibble_1;
    wire [3:0] swapped_nibble_0;

    // Nibble extraction
    nibble_extract u_nibble_extract (
        .din      (data_in),
        .n3       (nibble_3),
        .n2       (nibble_2),
        .n1       (nibble_1),
        .n0       (nibble_0)
    );

    // Nibble swapping logic
    nibble_swap_core u_nibble_swap_core (
        .n3         (nibble_3),
        .n2         (nibble_2),
        .n1         (nibble_1),
        .n0         (nibble_0),
        .swap_en    (swap_en),
        .sn3        (swapped_nibble_3),
        .sn2        (swapped_nibble_2),
        .sn1        (swapped_nibble_1),
        .sn0        (swapped_nibble_0)
    );

    // Nibble assembly
    nibble_assemble u_nibble_assemble (
        .n3       (swapped_nibble_3),
        .n2       (swapped_nibble_2),
        .n1       (swapped_nibble_1),
        .n0       (swapped_nibble_0),
        .dout     (data_out)
    );

endmodule

// -----------------------------------------------------------------------------
// Submodule: nibble_extract
// Function: Extracts 4-bit nibbles from 16-bit input
// -----------------------------------------------------------------------------
module nibble_extract(
    input  [15:0] din,
    output [3:0]  n3,
    output [3:0]  n2,
    output [3:0]  n1,
    output [3:0]  n0
);
    assign n3 = din[15:12];
    assign n2 = din[11:8];
    assign n1 = din[7:4];
    assign n0 = din[3:0];
endmodule

// -----------------------------------------------------------------------------
// Submodule: nibble_swap_core
// Function: Swaps the positions of the 4 nibbles based on swap_en
// -----------------------------------------------------------------------------
module nibble_swap_core(
    input  [3:0] n3,
    input  [3:0] n2,
    input  [3:0] n1,
    input  [3:0] n0,
    input        swap_en,
    output [3:0] sn3,
    output [3:0] sn2,
    output [3:0] sn1,
    output [3:0] sn0
);
    reg [3:0] sn3_reg, sn2_reg, sn1_reg, sn0_reg;

    always @(*) begin
        if (swap_en) begin
            sn3_reg = n0;
            sn2_reg = n1;
            sn1_reg = n2;
            sn0_reg = n3;
        end else begin
            sn3_reg = n3;
            sn2_reg = n2;
            sn1_reg = n1;
            sn0_reg = n0;
        end
    end

    assign sn3 = sn3_reg;
    assign sn2 = sn2_reg;
    assign sn1 = sn1_reg;
    assign sn0 = sn0_reg;
endmodule

// -----------------------------------------------------------------------------
// Submodule: nibble_assemble
// Function: Assembles 4 nibbles into a 16-bit output word
// -----------------------------------------------------------------------------
module nibble_assemble(
    input  [3:0] n3,
    input  [3:0] n2,
    input  [3:0] n1,
    input  [3:0] n0,
    output [15:0] dout
);
    assign dout = {n3, n2, n1, n0};
endmodule
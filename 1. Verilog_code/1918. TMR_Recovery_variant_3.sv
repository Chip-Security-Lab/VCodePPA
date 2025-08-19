//SystemVerilog
// Top-level module: Triple Modular Redundancy (TMR) Recovery with hierarchical structure
module TMR_Recovery #(parameter WIDTH=8) (
    input  [WIDTH-1:0] ch0,
    input  [WIDTH-1:0] ch1,
    input  [WIDTH-1:0] ch2,
    output [WIDTH-1:0] data_out
);

    // Internal wires to hold pairwise majority results
    wire [WIDTH-1:0] pairwise_01;
    wire [WIDTH-1:0] pairwise_12;
    wire [WIDTH-1:0] pairwise_02;

    // Pairwise AND between ch0 and ch1
    PairwiseAnd #(.WIDTH(WIDTH)) u_pairwise_and_01 (
        .a(ch0),
        .b(ch1),
        .and_out(pairwise_01)
    );

    // Pairwise AND between ch1 and ch2
    PairwiseAnd #(.WIDTH(WIDTH)) u_pairwise_and_12 (
        .a(ch1),
        .b(ch2),
        .and_out(pairwise_12)
    );

    // Pairwise AND between ch0 and ch2
    PairwiseAnd #(.WIDTH(WIDTH)) u_pairwise_and_02 (
        .a(ch0),
        .b(ch2),
        .and_out(pairwise_02)
    );

    // Majority voter: OR the three pairwise ANDs
    MajorityVoter #(.WIDTH(WIDTH)) u_majority_voter (
        .in0(pairwise_01),
        .in1(pairwise_12),
        .in2(pairwise_02),
        .majority_out(data_out)
    );

endmodule

//------------------------------------------------------------------------------
// PairwiseAnd: Performs bitwise AND between two input vectors
//------------------------------------------------------------------------------
module PairwiseAnd #(parameter WIDTH=8) (
    input  [WIDTH-1:0] a,
    input  [WIDTH-1:0] b,
    output [WIDTH-1:0] and_out
);
    assign and_out = a & b;
endmodule

//------------------------------------------------------------------------------
// MajorityVoter: Computes bitwise OR of three input vectors (for TMR recovery)
//------------------------------------------------------------------------------
module MajorityVoter #(parameter WIDTH=8) (
    input  [WIDTH-1:0] in0,
    input  [WIDTH-1:0] in1,
    input  [WIDTH-1:0] in2,
    output [WIDTH-1:0] majority_out
);
    assign majority_out = in0 | in1 | in2;
endmodule
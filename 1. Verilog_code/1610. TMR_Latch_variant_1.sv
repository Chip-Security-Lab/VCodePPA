//SystemVerilog
module TMR_Latch #(
    parameter DW = 8
) (
    input wire clk,
    input wire [DW-1:0] din,
    output wire [DW-1:0] dout
);

    // Pipeline stage 1: Input sampling
    reg [DW-1:0] stage1_reg1;
    reg [DW-1:0] stage1_reg2;
    reg [DW-1:0] stage1_reg3;

    // Pipeline stage 2: Majority voting
    reg [DW-1:0] stage2_vote_result;

    // Stage 1: Triple sampling
    always @(posedge clk) begin
        stage1_reg1 <= din;
        stage1_reg2 <= din;
        stage1_reg3 <= din;
    end

    // Stage 2: Majority voting logic
    wire [DW-1:0] vote_intermediate1 = stage1_reg1 & stage1_reg2;
    wire [DW-1:0] vote_intermediate2 = stage1_reg2 & stage1_reg3;
    wire [DW-1:0] vote_intermediate3 = stage1_reg1 & stage1_reg3;
    wire [DW-1:0] vote_result = vote_intermediate1 | vote_intermediate2 | vote_intermediate3;

    always @(posedge clk) begin
        stage2_vote_result <= vote_result;
    end

    // Output assignment
    assign dout = stage2_vote_result;

endmodule
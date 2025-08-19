//SystemVerilog
module nand4_4 (
    input  wire        clk,
    input  wire [3:0]  A,
    input  wire [3:0]  B,
    input  wire [3:0]  C,
    input  wire [3:0]  D,
    output wire [3:0]  Y
);

// Stage 1: Register inputs for clear dataflow and improved timing
reg [3:0] stage1_A;
reg [3:0] stage1_B;
reg [3:0] stage1_C;
reg [3:0] stage1_D;
always @(posedge clk) begin
    stage1_A <= A;
    stage1_B <= B;
    stage1_C <= C;
    stage1_D <= D;
end

// Stage 2: Pairwise AND of inputs to reduce logic depth
reg [3:0] stage2_and_AB;
reg [3:0] stage2_and_CD;
always @(posedge clk) begin
    stage2_and_AB <= stage1_A & stage1_B;
    stage2_and_CD <= stage1_C & stage1_D;
end

// Stage 3: Final AND and NAND operation
reg [3:0] stage3_and_all;
always @(posedge clk) begin
    stage3_and_all <= stage2_and_AB & stage2_and_CD;
end

// Stage 4: Output register for final result
reg [3:0] stage4_nand_out;
always @(posedge clk) begin
    stage4_nand_out <= ~stage3_and_all;
end

assign Y = stage4_nand_out;

endmodule
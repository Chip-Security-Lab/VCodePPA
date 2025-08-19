//SystemVerilog
module nor4_double_invert_pipeline (
    input  wire clk,
    input  wire rst_n,
    input  wire A,
    input  wire B,
    input  wire C,
    input  wire D,
    output wire Y
);

// Stage 1: Invert inputs and register
reg stage1_A_inv, stage1_B_inv, stage1_C_inv, stage1_D_inv;
always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
        stage1_A_inv <= 1'b0;
        stage1_B_inv <= 1'b0;
        stage1_C_inv <= 1'b0;
        stage1_D_inv <= 1'b0;
    end else begin
        stage1_A_inv <= ~A;
        stage1_B_inv <= ~B;
        stage1_C_inv <= ~C;
        stage1_D_inv <= ~D;
    end
end

// Stage 2: Pairwise AND and register
reg stage2_and_ab, stage2_and_cd;
always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
        stage2_and_ab <= 1'b0;
        stage2_and_cd <= 1'b0;
    end else begin
        stage2_and_ab <= stage1_A_inv & stage1_B_inv;
        stage2_and_cd <= stage1_C_inv & stage1_D_inv;
    end
end

// Stage 3: Final AND and output register
reg stage3_and_final;
always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
        stage3_and_final <= 1'b0;
    end else begin
        stage3_and_final <= stage2_and_ab & stage2_and_cd;
    end
end

assign Y = stage3_and_final;

endmodule
//SystemVerilog
module nand4_3 (
    input  wire clk,
    input  wire rst_n,
    input  wire A,
    input  wire B,
    input  wire C,
    input  wire D,
    output reg  Y
);

// Pipeline stage 1: Input latching
reg A_stage1, B_stage1, C_stage1, D_stage1;
always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
        A_stage1 <= 1'b0;
        B_stage1 <= 1'b0;
        C_stage1 <= 1'b0;
        D_stage1 <= 1'b0;
    end else begin
        A_stage1 <= A;
        B_stage1 <= B;
        C_stage1 <= C;
        D_stage1 <= D;
    end
end

// Pipeline stage 2: And-combine
reg ab_and_stage2, cd_and_stage2;
always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
        ab_and_stage2 <= 1'b0;
        cd_and_stage2 <= 1'b0;
    end else begin
        ab_and_stage2 <= A_stage1 & B_stage1;
        cd_and_stage2 <= C_stage1 & D_stage1;
    end
end

// Pipeline stage 3: Final AND and NAND output
reg and_final_stage3;
always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
        and_final_stage3 <= 1'b0;
    end else begin
        and_final_stage3 <= ab_and_stage2 & cd_and_stage2;
    end
end

// Output stage: NAND (flattened control flow)
always @(posedge clk or negedge rst_n) begin
    if (!rst_n)
        Y <= 1'b1;
    else if (rst_n && ~(ab_and_stage2 & cd_and_stage2))
        Y <= 1'b1;
    else if (rst_n && (ab_and_stage2 & cd_and_stage2))
        Y <= 1'b0;
end

endmodule
//SystemVerilog
module DiffLatch #(
    parameter DW = 8,
    parameter PIPELINE_STAGES = 2
)(
    input wire clk,
    input wire rst_n,
    input wire [DW-1:0] d_p,
    input wire [DW-1:0] d_n,
    output reg [DW-1:0] q
);

    // 流水线寄存器
    reg [DW-1:0] diff_stage [PIPELINE_STAGES-1:0];
    reg [DW-1:0] xor_stage1;
    reg [DW-1:0] xor_stage2;

    // 第一级差分计算
    always @(*) begin
        xor_stage1 = d_p ^ d_n;
    end

    // 第二级差分计算
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            xor_stage2 <= {DW{1'b0}};
        end else begin
            xor_stage2 <= xor_stage1;
        end
    end

    // 流水线寄存器阶段
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            for (integer i = 0; i < PIPELINE_STAGES; i = i + 1) begin
                diff_stage[i] <= {DW{1'b0}};
            end
            q <= {DW{1'b0}};
        end else begin
            diff_stage[0] <= xor_stage2;
            for (integer i = 1; i < PIPELINE_STAGES; i = i + 1) begin
                diff_stage[i] <= diff_stage[i-1];
            end
            q <= diff_stage[PIPELINE_STAGES-1];
        end
    end

endmodule
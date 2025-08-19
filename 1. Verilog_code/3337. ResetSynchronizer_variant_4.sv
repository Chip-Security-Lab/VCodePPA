//SystemVerilog
module ResetSynchronizer (
    input  wire clk,
    input  wire rst_n,
    output reg  rst_sync
);
    reg rst_ff1_stage1;
    reg rst_ff2_stage2;
    reg rst_ff3_stage3;

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            rst_ff1_stage1 <= 1'b0;
            rst_ff2_stage2 <= 1'b0;
            rst_ff3_stage3 <= 1'b0;
            rst_sync       <= 1'b0;
        end else begin
            rst_ff1_stage1 <= 1'b1;
            rst_ff2_stage2 <= rst_ff1_stage1;
            rst_ff3_stage3 <= rst_ff2_stage2;
            rst_sync       <= rst_ff3_stage3;
        end
    end
endmodule
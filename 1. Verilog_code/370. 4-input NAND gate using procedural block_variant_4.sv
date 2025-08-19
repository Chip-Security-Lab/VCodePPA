//SystemVerilog
module nand4_6 (
    input  wire clk,
    input  wire rst_n,
    input  wire A,
    input  wire B,
    input  wire C,
    input  wire D,
    output wire Y
);

    // Stage 1: Register inputs and perform AND operations in a single stage
    reg ab_and_stage1, cd_and_stage1;
    reg and_out_stage1;
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            ab_and_stage1   <= 1'b0;
            cd_and_stage1   <= 1'b0;
            and_out_stage1  <= 1'b0;
        end else begin
            ab_and_stage1   <= A & B;
            cd_and_stage1   <= C & D;
            and_out_stage1  <= (A & B) & (C & D);
        end
    end

    assign Y = ~and_out_stage1;

endmodule
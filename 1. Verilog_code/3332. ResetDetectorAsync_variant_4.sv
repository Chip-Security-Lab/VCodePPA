//SystemVerilog
module ResetDetectorAsync (
    input wire clk,
    input wire rst_n,
    output reg reset_detected
);

    reg reset_sync_stage1;
    reg reset_sync_stage2;

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            {reset_sync_stage2, reset_sync_stage1, reset_detected} <= 3'b111;
        end else begin
            reset_sync_stage1 <= 1'b0;
            reset_sync_stage2 <= reset_sync_stage1;
            reset_detected    <= reset_sync_stage2;
        end
    end

endmodule
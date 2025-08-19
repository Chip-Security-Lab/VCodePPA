module ResetSynchronizer (
    input wire clk,
    input wire rst_n,
    output reg rst_sync
);
    reg rst_ff1;
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            rst_ff1 <= 1'b0;
            rst_sync <= 1'b0;
        end else begin
            rst_ff1 <= 1'b1;
            rst_sync <= rst_ff1;
        end
    end
endmodule

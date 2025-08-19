//SystemVerilog
module reset_sync #(
    parameter STAGES = 2
) (
    input wire clk,
    input wire async_reset_n,
    output wire sync_reset_n
);

    reg [STAGES-2:0] reset_sync_reg_pre;
    reg sync_reset_n_reg;

    always @(posedge clk or negedge async_reset_n) begin
        if (!async_reset_n)
            reset_sync_reg_pre <= {STAGES-1{1'b0}};
        else
            reset_sync_reg_pre <= {reset_sync_reg_pre[STAGES-2:0], 1'b1};
    end

    always @(posedge clk or negedge async_reset_n) begin
        if (!async_reset_n)
            sync_reset_n_reg <= 1'b0;
        else
            sync_reset_n_reg <= reset_sync_reg_pre[STAGES-2];
    end

    assign sync_reset_n = sync_reset_n_reg;

endmodule
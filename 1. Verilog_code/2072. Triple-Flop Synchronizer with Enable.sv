module triple_flop_sync #(parameter DW = 16) (
    input wire dest_clock,
    input wire reset,
    input wire enable,
    input wire [DW-1:0] async_data,
    output reg [DW-1:0] sync_data
);
    reg [DW-1:0] stage1, stage2;
    
    always @(posedge dest_clock) begin
        if (reset) begin
            {stage1, stage2, sync_data} <= 0;
        end else if (enable) begin
            stage1 <= async_data;
            stage2 <= stage1;
            sync_data <= stage2;
        end
    end
endmodule
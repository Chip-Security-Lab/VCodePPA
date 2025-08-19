module basic_reset_sync (
    input  wire clk,
    input  wire async_reset_n,
    output reg  sync_reset_n
);
    reg meta_flop;
    
    always @(posedge clk or negedge async_reset_n) begin
        if (!async_reset_n) begin
            meta_flop <= 1'b0;
            sync_reset_n <= 1'b0;
        end else begin
            meta_flop <= 1'b1;
            sync_reset_n <= meta_flop;
        end
    end
endmodule
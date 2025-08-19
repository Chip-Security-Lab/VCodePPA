module level_sync_debounce #(parameter DEBOUNCE_COUNT = 3) (
    input wire src_clk, dst_clk, rst,
    input wire level_in,
    output reg level_out
);
    reg level_meta, level_sync;
    reg level_sync_prev;
    reg [3:0] stable_count;
    
    // Two-flop synchronizer
    always @(posedge dst_clk) begin
        if (rst) begin
            level_meta <= 1'b0;
            level_sync <= 1'b0;
        end else begin
            level_meta <= level_in;
            level_sync <= level_meta;
        end
    end
    
    // Debounce logic
    always @(posedge dst_clk) begin
        if (rst) begin
            stable_count <= 4'd0;
            level_sync_prev <= 1'b0;
            level_out <= 1'b0;
        end else begin
            level_sync_prev <= level_sync;
            
            if (level_sync != level_sync_prev)
                stable_count <= 4'd0;
            else if (stable_count < DEBOUNCE_COUNT)
                stable_count <= stable_count + 1'b1;
            else if (stable_count == DEBOUNCE_COUNT)
                level_out <= level_sync;
        end
    end
endmodule
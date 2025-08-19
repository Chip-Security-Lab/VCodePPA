//SystemVerilog
module level_sync_debounce #(parameter DEBOUNCE_COUNT = 3) (
    input wire src_clk,
    input wire dst_clk,
    input wire rst,
    input wire level_in,
    output reg level_out
);
    reg level_meta;
    reg level_sync;
    reg [3:0] stable_count;
    reg debounced_level;
    reg level_sync_prev;
    reg level_in_sync1, level_in_sync2;

    // Two-flop synchronizer moved after input for retiming
    always @(posedge dst_clk) begin
        if (rst) begin
            level_in_sync1 <= 1'b0;
            level_in_sync2 <= 1'b0;
        end else begin
            level_in_sync1 <= level_in;
            level_in_sync2 <= level_in_sync1;
        end
    end

    // Register stage (retimed): synchronize to dst_clk, then use in debounce logic
    always @(posedge dst_clk) begin
        if (rst) begin
            level_meta <= 1'b0;
            level_sync <= 1'b0;
        end else begin
            level_meta <= level_in_sync2;
            level_sync <= level_meta;
        end
    end

    // Debounce logic with retimed register
    always @(posedge dst_clk) begin
        if (rst) begin
            stable_count <= 4'd0;
            level_sync_prev <= 1'b0;
            debounced_level <= 1'b0;
        end else begin
            level_sync_prev <= level_sync;
            if (level_sync != level_sync_prev)
                stable_count <= 4'd0;
            else if (stable_count < DEBOUNCE_COUNT)
                stable_count <= stable_count + 1'b1;
            else if (stable_count == DEBOUNCE_COUNT)
                debounced_level <= level_sync;
        end
    end

    // Output register after debounce logic
    always @(posedge dst_clk) begin
        if (rst) begin
            level_out <= 1'b0;
        end else begin
            level_out <= debounced_level;
        end
    end

endmodule
//SystemVerilog
module level_sync_debounce #(parameter DEBOUNCE_COUNT = 3) (
    input wire src_clk,
    input wire dst_clk,
    input wire rst,
    input wire level_in,
    output reg level_out
);
    reg sync_stage_1;
    reg sync_stage_2;
    reg prev_sync_level;
    reg [3:0] debounce_counter;

    // Synchronizer logic (two-stage)
    always @(posedge dst_clk) begin
        if (rst) begin
            sync_stage_1 <= 1'b0;
            sync_stage_2 <= 1'b0;
        end else begin
            sync_stage_1 <= level_in;
            sync_stage_2 <= sync_stage_1;
        end
    end

    // Debounce logic with optimized comparison
    always @(posedge dst_clk) begin
        if (rst) begin
            debounce_counter <= 4'd0;
            prev_sync_level <= 1'b0;
            level_out <= 1'b0;
        end else begin
            prev_sync_level <= sync_stage_2;

            if (sync_stage_2 != prev_sync_level) begin
                debounce_counter <= 4'd0;
            end else if (debounce_counter < DEBOUNCE_COUNT) begin
                debounce_counter <= debounce_counter + 1'b1;
            end

            if ((debounce_counter == DEBOUNCE_COUNT) && (level_out != sync_stage_2)) begin
                level_out <= sync_stage_2;
            end
        end
    end
endmodule
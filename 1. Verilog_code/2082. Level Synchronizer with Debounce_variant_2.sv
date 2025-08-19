//SystemVerilog
`timescale 1ns/1ps
module level_sync_debounce #(
    parameter DEBOUNCE_COUNT = 3
) (
    input  wire src_clk,
    input  wire dst_clk,
    input  wire rst,
    input  wire level_in,
    output reg  level_out
);

    // Synchronizer registers
    reg sync_meta;
    reg sync_ff;
    reg sync_ff_prev;
    reg [3:0] debounce_cnt;

    // Synchronizer: stage 1
    always @(posedge dst_clk) begin
        if (rst) begin
            sync_meta <= 1'b0;
        end else begin
            sync_meta <= level_in;
        end
    end

    // Synchronizer: stage 2
    always @(posedge dst_clk) begin
        if (rst) begin
            sync_ff <= 1'b0;
        end else begin
            sync_ff <= sync_meta;
        end
    end

    // Synchronizer: previous state register
    always @(posedge dst_clk) begin
        if (rst) begin
            sync_ff_prev <= 1'b0;
        end else begin
            sync_ff_prev <= sync_ff;
        end
    end

    // Debounce counter
    always @(posedge dst_clk) begin
        if (rst) begin
            debounce_cnt <= 4'd0;
        end else if (sync_ff != sync_ff_prev) begin
            debounce_cnt <= 4'd0;
        end else if (debounce_cnt != DEBOUNCE_COUNT) begin
            debounce_cnt <= debounce_cnt + 1'b1;
        end
    end

    // Debounced output logic
    always @(posedge dst_clk) begin
        if (rst) begin
            level_out <= 1'b0;
        end else if ((sync_ff == sync_ff_prev) && (debounce_cnt == DEBOUNCE_COUNT)) begin
            level_out <= sync_ff;
        end
    end

endmodule
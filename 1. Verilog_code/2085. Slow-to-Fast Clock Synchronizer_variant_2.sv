//SystemVerilog
`timescale 1ns/1ps

module slow_to_fast_sync #(parameter WIDTH = 12) (
    input wire slow_clk,
    input wire fast_clk,
    input wire rst_n,
    input wire [WIDTH-1:0] slow_data,
    output reg [WIDTH-1:0] fast_data,
    output reg data_valid
);

    // Slow domain registers
    reg slow_toggle_stage1;
    reg slow_toggle_stage2;
    reg [WIDTH-1:0] capture_data_stage1;
    reg [WIDTH-1:0] capture_data_stage2;

    // CDC toggle sync pipeline in fast domain
    reg fast_toggle_sync_stage1;
    reg fast_toggle_sync_stage2;
    reg fast_toggle_sync_stage3;
    reg fast_toggle_sync_stage4;

    // Previous toggle for edge detection in fast domain
    reg fast_toggle_prev_stage1;
    reg fast_toggle_prev_stage2;

    // Data pipeline across CDC
    reg [WIDTH-1:0] capture_data_fast_stage1;
    reg [WIDTH-1:0] capture_data_fast_stage2;
    reg [WIDTH-1:0] capture_data_fast_stage3;
    reg [WIDTH-1:0] fast_data_stage1;
    reg [WIDTH-1:0] fast_data_stage2;

    // Data valid signal pipeline
    reg data_valid_stage1;
    reg data_valid_stage2;

    // Slow clock domain: Two-stage pipeline for toggle and data
    always @(posedge slow_clk or negedge rst_n) begin
        if (!rst_n) begin
            slow_toggle_stage1   <= 1'b0;
            slow_toggle_stage2   <= 1'b0;
            capture_data_stage1  <= {WIDTH{1'b0}};
            capture_data_stage2  <= {WIDTH{1'b0}};
        end else begin
            slow_toggle_stage1   <= ~slow_toggle_stage1;
            slow_toggle_stage2   <= slow_toggle_stage1;
            capture_data_stage1  <= slow_data;
            capture_data_stage2  <= capture_data_stage1;
        end
    end

    // Fast clock domain: Four-stage pipeline for toggle synchronizer
    always @(posedge fast_clk or negedge rst_n) begin
        if (!rst_n) begin
            fast_toggle_sync_stage1 <= 1'b0;
            fast_toggle_sync_stage2 <= 1'b0;
            fast_toggle_sync_stage3 <= 1'b0;
            fast_toggle_sync_stage4 <= 1'b0;
        end else begin
            fast_toggle_sync_stage1 <= slow_toggle_stage2;
            fast_toggle_sync_stage2 <= fast_toggle_sync_stage1;
            fast_toggle_sync_stage3 <= fast_toggle_sync_stage2;
            fast_toggle_sync_stage4 <= fast_toggle_sync_stage3;
        end
    end

    // Fast clock domain: Three-stage data pipeline for CDC
    always @(posedge fast_clk or negedge rst_n) begin
        if (!rst_n) begin
            capture_data_fast_stage1 <= {WIDTH{1'b0}};
            capture_data_fast_stage2 <= {WIDTH{1'b0}};
            capture_data_fast_stage3 <= {WIDTH{1'b0}};
        end else begin
            capture_data_fast_stage1 <= capture_data_stage2;
            capture_data_fast_stage2 <= capture_data_fast_stage1;
            capture_data_fast_stage3 <= capture_data_fast_stage2;
        end
    end

    // Fast clock domain: Edge detection and data valid pipeline
    always @(posedge fast_clk or negedge rst_n) begin
        if (!rst_n) begin
            fast_toggle_prev_stage1 <= 1'b0;
            fast_toggle_prev_stage2 <= 1'b0;
            fast_data_stage1        <= {WIDTH{1'b0}};
            fast_data_stage2        <= {WIDTH{1'b0}};
            data_valid_stage1       <= 1'b0;
            data_valid_stage2       <= 1'b0;
        end else begin
            fast_toggle_prev_stage1 <= fast_toggle_sync_stage4;
            fast_toggle_prev_stage2 <= fast_toggle_prev_stage1;

            data_valid_stage1  <= 1'b0;
            data_valid_stage2  <= data_valid_stage1;

            fast_data_stage1   <= fast_data_stage1; // Hold by default
            fast_data_stage2   <= fast_data_stage1;

            // Edge detect: pipeline increases depth for max freq
            if (fast_toggle_sync_stage4 != fast_toggle_prev_stage2) begin
                fast_data_stage1   <= capture_data_fast_stage3;
                data_valid_stage1  <= 1'b1;
            end
        end
    end

    // Fast clock domain: Output pipeline stage for fast_data and data_valid
    always @(posedge fast_clk or negedge rst_n) begin
        if (!rst_n) begin
            fast_data  <= {WIDTH{1'b0}};
            data_valid <= 1'b0;
        end else begin
            fast_data  <= fast_data_stage2;
            data_valid <= data_valid_stage2;
        end
    end

endmodule
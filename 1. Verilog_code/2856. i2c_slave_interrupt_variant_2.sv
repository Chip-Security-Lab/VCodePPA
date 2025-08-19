//SystemVerilog
`timescale 1ns / 1ps
module i2c_slave_interrupt(
    input  wire        clk,
    input  wire        reset,
    input  wire [6:0]  device_addr,
    output reg  [7:0]  data_out,
    output reg         data_ready,
    output reg         addr_match_int,
    output reg         data_int,
    output reg         error_int,
    inout              sda,
    inout              scl
);

    // Internal registers
    reg  [3:0] bit_count;
    reg  [2:0] state;
    reg  [7:0] rx_shift_reg;
    reg        sda_in_r, scl_in_r, sda_out;

    // Synchronized input signals (moved registers after combination logic)
    wire       sda_sync_comb, scl_sync_comb;

    // Pipeline registers for start/stop condition
    reg        start_condition_stage1, start_condition_stage2;
    reg        stop_condition_stage1,  stop_condition_stage2;

    // Remove input synchronizer registers; use combinational assignment
    assign sda_sync_comb = sda;
    assign scl_sync_comb = scl;

    // Pipeline input synchronizers after combination logic
    reg        sda_sync_pipeline, scl_sync_pipeline;

    always @(posedge clk or posedge reset) begin
        if (reset) begin
            sda_sync_pipeline <= 1'b1;
            scl_sync_pipeline <= 1'b1;
        end else begin
            sda_sync_pipeline <= sda_sync_comb;
            scl_sync_pipeline <= scl_sync_comb;
        end
    end

    // Register the synchronized signals for use (now after the pipeline)
    always @(posedge clk or posedge reset) begin
        if (reset) begin
            sda_in_r <= 1'b1;
            scl_in_r <= 1'b1;
        end else begin
            sda_in_r <= sda_sync_pipeline;
            scl_in_r <= scl_sync_pipeline;
        end
    end

    // Pipeline for start/stop condition detection (cutting long path)
    always @(posedge clk or posedge reset) begin
        if (reset) begin
            start_condition_stage1 <= 1'b0;
            start_condition_stage2 <= 1'b0;
            stop_condition_stage1  <= 1'b0;
            stop_condition_stage2  <= 1'b0;
        end else begin
            // Stage 1: Compute first half of the condition
            start_condition_stage1 <= scl_in_r && sda_in_r;
            stop_condition_stage1  <= scl_in_r && !sda_in_r;
            // Stage 2: Complete the condition with the pipelined signals
            start_condition_stage2 <= start_condition_stage1 && !sda_sync_pipeline;
            stop_condition_stage2  <= stop_condition_stage1  && sda_sync_pipeline;
        end
    end

    // State Machine
    always @(posedge clk or posedge reset) begin
        if (reset) begin
            state           <= 3'b000;
            data_int        <= 1'b0;
            data_out        <= 8'b0;
            data_ready      <= 1'b0;
            addr_match_int  <= 1'b0;
            error_int       <= 1'b0;
        end else begin
            case (state)
                3'b000: begin
                    if (start_condition_stage2)
                        state <= 3'b001;
                end
                3'b011: begin
                    data_out <= rx_shift_reg;
                    data_int <= 1'b1;
                end
                default: begin
                    // Add default assignments if needed
                end
            endcase
        end
    end

endmodule
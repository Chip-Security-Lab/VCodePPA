//SystemVerilog
module UART_BreakDetect #(
    parameter BREAK_MIN = 16
)(
    input wire clk,
    input wire rst_n,
    input wire rxd,
    output reg break_event,
    output reg [15:0] break_duration
);

// Stage 1: Input synchronizer and filter
reg [2:0] rxd_filter_stage1;
reg rxd_stage1;
reg valid_stage1;
always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
        rxd_filter_stage1 <= 3'b111;
        rxd_stage1 <= 1'b1;
        valid_stage1 <= 1'b0;
    end else begin
        rxd_filter_stage1 <= {rxd_filter_stage1[1:0], rxd};
        rxd_stage1 <= rxd;
        valid_stage1 <= 1'b1;
    end
end

// Stage 2: Debounce result and edge detection
reg rxd_debounced_stage2;
reg rxd_last_stage2;
reg valid_stage2;
always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
        rxd_debounced_stage2 <= 1'b1;
        rxd_last_stage2 <= 1'b1;
        valid_stage2 <= 1'b0;
    end else begin
        rxd_debounced_stage2 <= (rxd_filter_stage1[2] & rxd_filter_stage1[1]) ? 1'b1 :
                                (~rxd_filter_stage1[2] & ~rxd_filter_stage1[1]) ? 1'b0 : rxd_debounced_stage2;
        rxd_last_stage2 <= rxd_stage1;
        valid_stage2 <= valid_stage1;
    end
end

// Stage 3: Low counter and break detection
reg [15:0] low_counter_stage3;
reg break_detected_stage3;
reg [15:0] break_duration_stage3;
reg valid_stage3;
always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
        low_counter_stage3 <= 16'd0;
        break_detected_stage3 <= 1'b0;
        break_duration_stage3 <= 16'd0;
        valid_stage3 <= 1'b0;
    end else if (valid_stage2) begin
        if (rxd_debounced_stage2 == 1'b0) begin
            low_counter_stage3 <= low_counter_stage3 + 1'b1;
            break_detected_stage3 <= 1'b0;
            break_duration_stage3 <= break_duration_stage3;
        end else begin
            if (low_counter_stage3 > BREAK_MIN) begin
                break_detected_stage3 <= 1'b1;
                break_duration_stage3 <= low_counter_stage3;
            end else begin
                break_detected_stage3 <= 1'b0;
                break_duration_stage3 <= break_duration_stage3;
            end
            low_counter_stage3 <= 16'd0;
        end
        valid_stage3 <= 1'b1;
    end else begin
        valid_stage3 <= 1'b0;
    end
end

// Stage 4: Output register and break event clear (flush) logic
reg break_event_stage4;
reg [15:0] break_duration_stage4;
reg flush_stage4;
always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
        break_event_stage4 <= 1'b0;
        break_duration_stage4 <= 16'd0;
        flush_stage4 <= 1'b0;
    end else if (valid_stage3) begin
        if (break_detected_stage3) begin
            break_event_stage4 <= 1'b1;
            break_duration_stage4 <= break_duration_stage3;
        end else if (rxd_filter_stage1[2] & rxd_filter_stage1[1]) begin
            // flush break event when rxd is high for 2 cycles (debounced)
            break_event_stage4 <= 1'b0;
            break_duration_stage4 <= break_duration_stage4;
        end
        flush_stage4 <= (rxd_filter_stage1[2] & rxd_filter_stage1[1]);
    end
end

// Output assignments
always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
        break_event <= 1'b0;
        break_duration <= 16'd0;
    end else begin
        break_event <= break_event_stage4;
        break_duration <= break_duration_stage4;
    end
end

endmodule
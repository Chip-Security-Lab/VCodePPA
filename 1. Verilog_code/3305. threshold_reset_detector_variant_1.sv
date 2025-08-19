//SystemVerilog
module threshold_reset_detector #(parameter WIDTH = 8)(
    input clk,
    input enable,
    input [WIDTH-1:0] voltage_level,
    input [WIDTH-1:0] threshold,
    output reg reset_out
);
    reg [2:0] consecutive_under = 3'd0;
    reg [2:0] consecutive_under_next;
    reg reset_out_next;

    // 中间变量用于简化条件判断
    wire voltage_below_threshold = (voltage_level < threshold);
    wire under_limit_reached     = (consecutive_under < 3'd5);
    wire under_limit_maxed       = (consecutive_under >= 3'd5);
    wire consecutive_will_be_3_or_more = ((consecutive_under + 3'd1) >= 3'd3);

    always @* begin
        // 默认保持当前状态
        consecutive_under_next = consecutive_under;
        reset_out_next = reset_out;

        if (!enable) begin
            consecutive_under_next = 3'd0;
            reset_out_next = 1'b0;
        end else begin
            if (voltage_below_threshold) begin
                if (under_limit_reached) begin
                    consecutive_under_next = consecutive_under + 3'd1;
                    reset_out_next = consecutive_will_be_3_or_more;
                end else begin
                    consecutive_under_next = 3'd5;
                    reset_out_next = 1'b1;
                end
            end else begin
                // voltage_level >= threshold
                consecutive_under_next = 3'd0;
                reset_out_next = 1'b0;
            end
        end
    end

    always @(posedge clk) begin
        consecutive_under <= consecutive_under_next;
        reset_out <= reset_out_next;
    end
endmodule
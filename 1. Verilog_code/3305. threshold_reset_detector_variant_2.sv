//SystemVerilog
// SystemVerilog
module threshold_reset_detector #(parameter WIDTH = 8)(
    input  wire                  clk,
    input  wire                  enable,
    input  wire [WIDTH-1:0]      voltage_level,
    input  wire [WIDTH-1:0]      threshold,
    output reg                   reset_out
);

    reg [2:0] consecutive_below;
    wire      voltage_below_threshold;
    wire      counter_saturated;

    assign voltage_below_threshold = (voltage_level < threshold);
    assign counter_saturated = (consecutive_below >= 3'd5);

    // Counter logic: Updates consecutive_below based on voltage and enable
    // Function: Tracks consecutive cycles voltage is below threshold, saturating at 5
    always @(posedge clk) begin
        if (!enable) begin
            consecutive_below <= 3'd0;
        end else if (voltage_below_threshold) begin
            if (!counter_saturated)
                consecutive_below <= consecutive_below + 3'd1;
            else
                consecutive_below <= 3'd5;
        end else begin
            consecutive_below <= 3'd0;
        end
    end

    // Reset logic: Sets reset_out when consecutive_below reaches 3 cycles or more
    // Function: Generates reset_out signal based on counter, clears on !enable
    always @(posedge clk) begin
        if (!enable) begin
            reset_out <= 1'b0;
        end else begin
            reset_out <= (consecutive_below >= 3'd3);
        end
    end

endmodule
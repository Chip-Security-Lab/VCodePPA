//SystemVerilog
module threshold_reset_detector #(parameter WIDTH = 8)(
    input  wire                  clk,
    input  wire                  enable,
    input  wire [WIDTH-1:0]      voltage_level,
    input  wire [WIDTH-1:0]      threshold,
    output reg                   reset_out
);
    reg [2:0] below_counter = 3'd0;
    wire      is_below_threshold;
    wire      is_counter_limit;

    assign is_below_threshold = (voltage_level < threshold);
    assign is_counter_limit   = (below_counter == 3'd5);

    always @(posedge clk) begin
        if (!enable) begin
            below_counter <= 3'd0;
            reset_out     <= 1'b0;
        end else begin
            if (is_below_threshold) begin
                below_counter <= is_counter_limit ? below_counter : below_counter + 3'd1;
            end else begin
                below_counter <= 3'd0;
            end
            reset_out <= (below_counter[2] | below_counter[1]) & is_below_threshold;
        end
    end
endmodule
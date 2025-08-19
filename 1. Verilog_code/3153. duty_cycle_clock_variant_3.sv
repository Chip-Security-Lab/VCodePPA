//SystemVerilog
module duty_cycle_clock #(
    parameter WIDTH = 8
)(
    input wire clkin,
    input wire reset,
    input wire [WIDTH-1:0] high_time,
    input wire [WIDTH-1:0] low_time,
    output reg clkout
);
    reg [WIDTH-1:0] counter = 0;
    reg counter_reset;
    reg next_clkout;
    wire counter_max_reached;
    wire [WIDTH-1:0] threshold;
    
    // Pre-compute threshold based on current clkout state
    assign threshold = clkout ? high_time : low_time;
    
    // Compare counter with threshold in a separate logic stage
    assign counter_max_reached = (counter >= threshold);
    
    always @(*) begin
        // Split logic for counter_reset and next_clkout into separate, simpler expressions
        counter_reset = counter_max_reached;
        next_clkout = counter_max_reached ? ~clkout : clkout;
    end
    
    always @(posedge clkin or posedge reset) begin
        if (reset) begin
            counter <= 0;
            clkout <= 0;
        end else begin
            if (counter_reset) begin
                counter <= 0;
                clkout <= next_clkout;
            end else begin
                counter <= counter + 1;
            end
        end
    end
endmodule
module deadband_generator #(
    parameter COUNTER_WIDTH = 10
)(
    input wire clock,
    input wire reset,
    input wire [COUNTER_WIDTH-1:0] period,
    input wire [COUNTER_WIDTH-1:0] deadtime,
    output reg signal_a,
    output reg signal_b
);
    reg [COUNTER_WIDTH-1:0] counter;
    
    always @(posedge clock) begin
        if (reset) begin
            counter <= {COUNTER_WIDTH{1'b0}};
            signal_a <= 1'b0;
            signal_b <= 1'b0;
        end else begin
            if (counter >= period - 1) begin
                counter <= {COUNTER_WIDTH{1'b0}};
            end else begin
                counter <= counter + 1'b1;
            end
            
            // First half of period minus deadtime
            if (counter < (period >> 1) - deadtime) begin
                signal_a <= 1'b1;
                signal_b <= 1'b0;
            // Second half of period minus deadtime
            end else if (counter >= (period >> 1) + deadtime) begin
                signal_a <= 1'b0;
                signal_b <= 1'b1;
            // Deadband region
            end else begin
                signal_a <= 1'b0;
                signal_b <= 1'b0;
            end
        end
    end
endmodule
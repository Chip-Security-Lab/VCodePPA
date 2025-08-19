module spread_spectrum_clk(
    input clock_in,
    input reset,
    input enable_spread,
    input [3:0] spread_amount,
    output reg clock_out
);
    reg [3:0] counter, period;
    reg direction;
    
    always @(posedge clock_in or posedge reset) begin
        if (reset) begin
            counter <= 4'b0;
            period <= 4'd8;
            direction <= 1'b0;
            clock_out <= 1'b0;
        end else begin
            if (counter >= period) begin
                counter <= 4'b0;
                clock_out <= ~clock_out;
                
                // Update period for next half-cycle
                if (enable_spread) begin
                    if (direction) begin
                        if (period < 4'd8 + spread_amount)
                            period <= period + 4'd1;
                        else
                            direction <= 1'b0;
                    end else begin
                        if (period > 4'd8 - spread_amount)
                            period <= period - 4'd1;
                        else
                            direction <= 1'b1;
                    end
                end else
                    period <= 4'd8;
            end else
                counter <= counter + 4'b1;
        end
    end
endmodule
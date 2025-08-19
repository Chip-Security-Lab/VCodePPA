//SystemVerilog
module spread_spectrum_clk(
    input wire clock_in,
    input wire reset,
    
    // Valid-Ready Input Interface
    input wire i_valid,
    output reg o_ready,
    input wire enable_spread,
    input wire [3:0] spread_amount,
    
    // Valid-Ready Output Interface
    output reg o_valid,
    input wire i_ready,
    output reg clock_out
);
    reg [3:0] counter, period;
    reg direction;
    reg params_captured;
    reg [3:0] latched_spread_amount;
    reg latched_enable_spread;
    
    // Input handshake logic - manages parameter capture
    always @(posedge clock_in or posedge reset) begin
        if (reset) begin
            o_ready <= 1'b1;
            params_captured <= 1'b0;
        end else begin
            if (i_valid && o_ready) begin
                params_captured <= 1'b1;
                o_ready <= 1'b0;  // Deassert ready after capturing
            end else if (!i_valid && params_captured) begin
                o_ready <= 1'b1;  // Ready for next input when current is processed
            end
        end
    end
    
    // Parameter latch control - stores input parameters
    always @(posedge clock_in or posedge reset) begin
        if (reset) begin
            latched_enable_spread <= 1'b0;
            latched_spread_amount <= 4'b0;
        end else if (i_valid && o_ready) begin
            // Capture input parameters when valid and ready
            latched_enable_spread <= enable_spread;
            latched_spread_amount <= spread_amount;
        end
    end
    
    // Counter management logic
    always @(posedge clock_in or posedge reset) begin
        if (reset) begin
            counter <= 4'b0;
        end else begin
            if (counter >= period) begin
                counter <= 4'b0;
            end else begin
                counter <= counter + 4'b1;
            end
        end
    end
    
    // Clock generation logic
    always @(posedge clock_in or posedge reset) begin
        if (reset) begin
            clock_out <= 1'b0;
            o_valid <= 1'b0;
        end else begin
            if (counter >= period) begin
                clock_out <= ~clock_out;
                o_valid <= 1'b1;  // Signal that new output is valid
            end
            
            // Reset valid flag when downstream has acknowledged
            if (o_valid && i_ready) begin
                o_valid <= 1'b0;
            end
        end
    end
    
    // Period management logic - handles spread spectrum functionality
    always @(posedge clock_in or posedge reset) begin
        if (reset) begin
            period <= 4'd8;
            direction <= 1'b0;
        end else if (counter >= period && params_captured) begin
            if (latched_enable_spread) begin
                if (direction) begin
                    if (period < 4'd8 + latched_spread_amount)
                        period <= period + 4'd1;
                    else
                        direction <= 1'b0;
                end else begin
                    if (period > 4'd8 - latched_spread_amount)
                        period <= period - 4'd1;
                    else
                        direction <= 1'b1;
                end
            end else begin
                period <= 4'd8;
            end
        end
    end
endmodule
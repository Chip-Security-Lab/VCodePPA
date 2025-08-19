//SystemVerilog
module peak_detection_recovery (
    input wire clk,
    input wire rst_n,
    input wire [9:0] signal_in,
    output reg [9:0] peak_value,
    output reg peak_detected
);
    // Registered input signal
    reg [9:0] signal_in_reg;
    reg [9:0] prev_value;
    reg is_rising_edge;
    reg is_falling_edge;
    
    // Input signal registration
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            signal_in_reg <= 10'h0;
        end else begin
            signal_in_reg <= signal_in;
        end
    end
    
    // Previous value tracking
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            prev_value <= 10'h0;
        end else begin
            prev_value <= signal_in_reg;
        end
    end
    
    // Edge detection logic
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            is_rising_edge <= 1'b0;
            is_falling_edge <= 1'b0;
        end else begin
            is_rising_edge <= (signal_in_reg > prev_value);
            is_falling_edge <= (signal_in < signal_in_reg);
        end
    end
    
    // Peak detection and output generation
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            peak_value <= 10'h0;
            peak_detected <= 1'b0;
        end else begin
            if (is_rising_edge && is_falling_edge) begin
                peak_value <= signal_in_reg;
                peak_detected <= 1'b1;
            end else begin
                peak_detected <= 1'b0;
            end
        end
    end
endmodule
module peak_detection_recovery (
    input wire clk,
    input wire rst_n,
    input wire [9:0] signal_in,
    output reg [9:0] peak_value,
    output reg peak_detected
);
    reg [9:0] prev_value;
    reg [9:0] prev_prev_value;
    
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            prev_value <= 10'h0;
            prev_prev_value <= 10'h0;
            peak_value <= 10'h0;
            peak_detected <= 1'b0;
        end else begin
            prev_prev_value <= prev_value;
            prev_value <= signal_in;
            
            // Detect local maximum
            if ((prev_value > prev_prev_value) && (prev_value > signal_in)) begin
                peak_value <= prev_value;
                peak_detected <= 1'b1;
            end else begin
                peak_detected <= 1'b0;
            end
        end
    end
endmodule
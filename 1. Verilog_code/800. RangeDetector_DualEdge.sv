module RangeDetector_DualEdge #(
    parameter WIDTH = 8
)(
    input clk, rst_n,
    input [WIDTH-1:0] data_in,
    input [WIDTH-1:0] threshold,
    output reg rise_detected,
    output reg fall_detected
);
reg prev_state;

always @(posedge clk or negedge rst_n) begin
    if(!rst_n) begin
        prev_state <= 0;
        rise_detected <= 0;
        fall_detected <= 0;
    end
    else begin
        prev_state <= (data_in >= threshold);
        rise_detected <= (!prev_state && (data_in >= threshold));
        fall_detected <= (prev_state && (data_in < threshold));
    end
end
endmodule
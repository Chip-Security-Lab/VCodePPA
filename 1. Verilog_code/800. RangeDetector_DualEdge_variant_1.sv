//SystemVerilog
module RangeDetector_DualEdge #(
    parameter WIDTH = 8
)(
    input clk, rst_n,
    input [WIDTH-1:0] data_in,
    input [WIDTH-1:0] threshold,
    output reg rise_detected,
    output reg fall_detected
);

// Buffered inputs to reduce fan-out
reg [WIDTH-1:0] data_in_buf1, data_in_buf2;
// Intermediate comparison results
reg comp_result_1, comp_result_2;
reg prev_state;

// Buffer the high fan-out data_in signal
always @(posedge clk or negedge rst_n) begin
    if(!rst_n) begin
        data_in_buf1 <= 0;
        data_in_buf2 <= 0;
    end
    else begin
        data_in_buf1 <= data_in;
        data_in_buf2 <= data_in;
    end
end

// Split comparison logic to balance loads
always @(posedge clk or negedge rst_n) begin
    if(!rst_n) begin
        comp_result_1 <= 0;
        comp_result_2 <= 0;
    end
    else begin
        comp_result_1 <= (data_in_buf1 >= threshold);
        comp_result_2 <= (data_in_buf2 < threshold);
    end
end

// Edge detection logic using buffered signals
always @(posedge clk or negedge rst_n) begin
    if(!rst_n) begin
        prev_state <= 0;
        rise_detected <= 0;
        fall_detected <= 0;
    end
    else begin
        prev_state <= comp_result_1;
        rise_detected <= (!prev_state && comp_result_1);
        fall_detected <= (prev_state && comp_result_2);
    end
end

endmodule
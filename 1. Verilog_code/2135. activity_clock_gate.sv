module activity_clock_gate (
    input  wire clk_in,
    input  wire [7:0] data_in,
    input  wire [7:0] prev_data,
    output wire clk_out
);
    wire activity_detected;
    
    assign activity_detected = (data_in != prev_data);
    assign clk_out = clk_in & activity_detected;
endmodule
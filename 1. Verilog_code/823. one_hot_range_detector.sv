module one_hot_range_detector(
    input wire clk,
    input wire [7:0] data_val,
    input wire [7:0] range1_low, range1_high,
    input wire [7:0] range2_low, range2_high,
    input wire [7:0] range3_low, range3_high,
    output reg [2:0] range_match // One-hot encoded
);
    wire r1, r2, r3;
    
    assign r1 = (data_val >= range1_low) && (data_val <= range1_high);
    assign r2 = (data_val >= range2_low) && (data_val <= range2_high);
    assign r3 = (data_val >= range3_low) && (data_val <= range3_high);
    
    always @(posedge clk) range_match <= {r3, r2, r1};
endmodule
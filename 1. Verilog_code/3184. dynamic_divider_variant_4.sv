//SystemVerilog
module dynamic_divider #(
    parameter CTR_WIDTH = 8
)(
    input clk,
    input [CTR_WIDTH-1:0] div_value,
    input load,
    output reg clk_div
);
    reg [CTR_WIDTH-1:0] counter;
    reg [CTR_WIDTH-1:0] current_div;
    reg [CTR_WIDTH-1:0] threshold;
    reg [CTR_WIDTH-1:0] inverted_counter;
    reg [CTR_WIDTH-1:0] inverted_threshold;
    reg counter_gt_threshold;

    always @(posedge clk) begin
        current_div <= load ? div_value : current_div;
    end

    always @(posedge clk) begin
        // Calculate threshold (current_div-1)
        threshold <= current_div - 1'b1;
        
        // Invert counter and threshold for comparison
        inverted_counter <= ~counter;
        inverted_threshold <= ~threshold;
        
        // Compare using inverted values (counter >= threshold is equivalent to inverted_counter <= inverted_threshold)
        counter_gt_threshold <= (inverted_counter <= inverted_threshold);
        
        // Update counter and clk_div based on comparison result
        counter <= counter_gt_threshold ? 0 : counter + 1'b1;
        clk_div <= counter_gt_threshold ? ~clk_div : clk_div;
    end
endmodule
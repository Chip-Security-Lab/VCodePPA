//SystemVerilog
module threshold_comparator(
    input clk,
    input rst,
    input [7:0] threshold,  // Programmable threshold value
    input [7:0] data_input,
    input load_threshold,   // Control signal to update threshold
    output reg above_threshold,
    output reg below_threshold,
    output reg at_threshold
);
    // Internal threshold register
    reg [7:0] threshold_reg;
    
    // Threshold register update logic - Optimized with default signal
    always @(posedge clk) begin
        if (rst) begin
            threshold_reg <= 8'h00;
        end else if (load_threshold) begin
            threshold_reg <= threshold;
        end
    end
    
    // Pre-compute comparison results to improve timing
    reg comp_above, comp_below, comp_equal;
    
    // Optimized comparison logic using single combinational block
    always @(*) begin
        comp_equal = (data_input == threshold_reg);
        comp_above = (data_input > threshold_reg);
        comp_below = ~(comp_equal | comp_above);
    end
    
    // Register comparison outputs with synchronized reset
    always @(posedge clk) begin
        if (rst) begin
            above_threshold <= 1'b0;
            below_threshold <= 1'b0;
            at_threshold <= 1'b0;
        end else begin
            above_threshold <= comp_above;
            below_threshold <= comp_below;
            at_threshold <= comp_equal;
        end
    end
endmodule
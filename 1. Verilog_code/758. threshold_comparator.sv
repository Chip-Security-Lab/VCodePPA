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
    
    // Threshold register update logic
    always @(posedge clk or posedge rst) begin
        if (rst) begin
            threshold_reg <= 8'h00;
        end else if (load_threshold) begin
            threshold_reg <= threshold;
        end
    end
    
    // Comparison logic - Data vs Threshold
    always @(posedge clk or posedge rst) begin
        if (rst) begin
            above_threshold <= 1'b0;
            below_threshold <= 1'b0;
            at_threshold <= 1'b0;
        end else begin
            above_threshold <= (data_input > threshold_reg);
            below_threshold <= (data_input < threshold_reg);
            at_threshold <= (data_input == threshold_reg);
        end
    end
endmodule
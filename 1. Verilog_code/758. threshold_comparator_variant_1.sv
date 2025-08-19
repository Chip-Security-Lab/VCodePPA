//SystemVerilog
module threshold_comparator(
    input clk,
    input rst,
    input [7:0] threshold,
    input [7:0] data_input,
    input load_threshold,
    output reg above_threshold,
    output reg below_threshold,
    output reg at_threshold
);
    // Internal threshold register
    reg [7:0] threshold_reg;
    
    // Clock buffering for different logic blocks
    wire clk_thresh_reg;
    wire clk_above_comp;
    wire clk_below_comp;
    wire clk_at_comp;
    
    // Clock buffer instantiation (implementation dependent)
    assign clk_thresh_reg = clk;
    assign clk_above_comp = clk;
    assign clk_below_comp = clk;
    assign clk_at_comp = clk;
    
    // Data input buffering for comparison logic paths
    reg [7:0] data_input_above;
    reg [7:0] data_input_below;
    reg [7:0] data_input_equal;
    
    // Buffer input data for different comparison paths
    always @(posedge clk or posedge rst) begin
        if (rst) begin
            data_input_above <= 8'h00;
            data_input_below <= 8'h00;
            data_input_equal <= 8'h00;
        end else begin
            data_input_above <= data_input;
            data_input_below <= data_input;
            data_input_equal <= data_input;
        end
    end
    
    // Threshold register update logic
    always @(posedge clk_thresh_reg or posedge rst) begin
        if (rst) begin
            threshold_reg <= 8'h00;
        end else if (load_threshold) begin
            threshold_reg <= threshold;
        end
    end
    
    // Above threshold comparison logic
    always @(posedge clk_above_comp or posedge rst) begin
        if (rst) begin
            above_threshold <= 1'b0;
        end else begin
            above_threshold <= (data_input_above > threshold_reg);
        end
    end
    
    // Below threshold comparison logic
    always @(posedge clk_below_comp or posedge rst) begin
        if (rst) begin
            below_threshold <= 1'b0;
        end else begin
            below_threshold <= (data_input_below < threshold_reg);
        end
    end
    
    // Equal to threshold comparison logic
    always @(posedge clk_at_comp or posedge rst) begin
        if (rst) begin
            at_threshold <= 1'b0;
        end else begin
            at_threshold <= (data_input_equal == threshold_reg);
        end
    end
endmodule
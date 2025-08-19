//SystemVerilog
// SystemVerilog
module multi_channel_range_detector(
    input wire clk,
    input wire rst,
    input wire [7:0] data_ch1, data_ch2,
    input wire [7:0] lower_bound, upper_bound,
    input wire data_valid_in,
    output reg ch1_in_range, ch2_in_range,
    output reg data_valid_out
);
    // Optimized stage structure with direct range comparison
    // Stage 1: Input registration and efficient range detection
    reg [7:0] data_ch1_reg, data_ch2_reg;
    reg [7:0] lower_bound_reg, upper_bound_reg;
    reg data_valid_reg1, data_valid_reg2;
    
    // Pre-calculated range test results
    reg ch1_in_range_calc, ch2_in_range_calc;
    
    // Stage 1: Register inputs and pre-calculate range conditions
    always @(posedge clk) begin
        if (rst) begin
            data_ch1_reg <= 8'b0;
            data_ch2_reg <= 8'b0;
            lower_bound_reg <= 8'b0;
            upper_bound_reg <= 8'b0;
            data_valid_reg1 <= 1'b0;
            
            // Pre-calculate range checks in a single stage
            ch1_in_range_calc <= 1'b0;
            ch2_in_range_calc <= 1'b0;
        end
        else begin
            data_ch1_reg <= data_ch1;
            data_ch2_reg <= data_ch2;
            lower_bound_reg <= lower_bound;
            upper_bound_reg <= upper_bound;
            data_valid_reg1 <= data_valid_in;
            
            // Single-stage range check optimization
            // Using a single expression reduces logic depth
            ch1_in_range_calc <= (data_ch1 >= lower_bound) && (data_ch1 <= upper_bound);
            ch2_in_range_calc <= (data_ch2 >= lower_bound) && (data_ch2 <= upper_bound);
        end
    end
    
    // Pipeline register for stage 2
    always @(posedge clk) begin
        if (rst) begin
            ch1_in_range <= 1'b0;
            ch2_in_range <= 1'b0;
            data_valid_reg2 <= 1'b0;
            data_valid_out <= 1'b0;
        end
        else begin
            ch1_in_range <= ch1_in_range_calc;
            ch2_in_range <= ch2_in_range_calc;
            data_valid_reg2 <= data_valid_reg1;
            data_valid_out <= data_valid_reg2;
        end
    end
endmodule
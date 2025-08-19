//SystemVerilog
module hysteresis_range_detector(
    input wire clock, reset_n,
    input wire [7:0] input_data,
    input wire [7:0] low_bound, high_bound,
    input wire [3:0] hysteresis,
    output reg in_valid_range
);
    // Register inputs to reduce input-to-register delay
    reg [7:0] input_data_reg, low_bound_reg, high_bound_reg;
    reg [3:0] hysteresis_reg;
    
    // Registered version of in_valid_range for feedback
    reg in_valid_range_fb;
    
    // Register all inputs first
    always @(posedge clock or negedge reset_n) begin
        if (!reset_n) begin
            input_data_reg <= 8'b0;
            low_bound_reg <= 8'b0;
            high_bound_reg <= 8'b0;
            hysteresis_reg <= 4'b0;
            in_valid_range_fb <= 1'b0;
        end else begin
            input_data_reg <= input_data;
            low_bound_reg <= low_bound;
            high_bound_reg <= high_bound;
            hysteresis_reg <= hysteresis;
            in_valid_range_fb <= in_valid_range;
        end
    end
    
    // Compute range check using registered inputs
    wire [7:0] effective_low = in_valid_range_fb ? (low_bound_reg - hysteresis_reg) : low_bound_reg;
    wire [7:0] effective_high = in_valid_range_fb ? (high_bound_reg + hysteresis_reg) : high_bound_reg;
    wire in_range_now = (input_data_reg >= effective_low) && (input_data_reg <= effective_high);
    
    // Output register
    always @(posedge clock or negedge reset_n)
        if (!reset_n) in_valid_range <= 1'b0;
        else in_valid_range <= in_range_now;
endmodule
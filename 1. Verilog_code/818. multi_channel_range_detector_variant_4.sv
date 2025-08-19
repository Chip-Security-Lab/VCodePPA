//SystemVerilog
module multi_channel_range_detector(
    input wire clk,
    input wire [7:0] data_ch1, data_ch2,
    input wire [7:0] lower_bound, upper_bound,
    output reg ch1_in_range, ch2_in_range
);
    // Register inputs first to reduce input-to-register delay
    reg [7:0] data_ch1_reg, data_ch2_reg;
    reg [7:0] lower_bound_reg, upper_bound_reg;
    
    always @(posedge clk) begin
        data_ch1_reg <= data_ch1;
        data_ch2_reg <= data_ch2;
        lower_bound_reg <= lower_bound;
        upper_bound_reg <= upper_bound;
    end
    
    // Comparison logic moved after registers
    wire ch1_result, ch2_result;
    
    assign ch1_result = (data_ch1_reg >= lower_bound_reg) && (data_ch1_reg <= upper_bound_reg);
    assign ch2_result = (data_ch2_reg >= lower_bound_reg) && (data_ch2_reg <= upper_bound_reg);
    
    always @(posedge clk) begin
        ch1_in_range <= ch1_result;
        ch2_in_range <= ch2_result;
    end
endmodule
//SystemVerilog
module serial_range_detector(
    input wire clk, rst, data_bit, valid,
    input wire [7:0] lower, upper,
    output reg in_range
);
    reg [7:0] shift_reg;
    reg [2:0] bit_count;
    
    // Retimed registers for comparison results
    reg greater_equal_lower_reg, less_equal_upper_reg;
    
    // Manchester carry chain signals
    wire [7:0] compare_lower_p, compare_lower_g;
    wire [7:0] compare_upper_p, compare_upper_g;
    wire [8:0] compare_lower_c, compare_upper_c;
    wire greater_equal_lower, less_equal_upper;
    
    // Generate propagate and generate signals for lower bound comparison
    assign compare_lower_p[7:0] = ~(shift_reg[7:0] ^ lower[7:0]);
    assign compare_lower_g[7:0] = shift_reg[7:0] & ~lower[7:0];
    
    // Generate propagate and generate signals for upper bound comparison
    assign compare_upper_p[7:0] = ~(shift_reg[7:0] ^ upper[7:0]);
    assign compare_upper_g[7:0] = ~shift_reg[7:0] & upper[7:0];
    
    // Manchester carry chain for lower bound comparison (>=)
    assign compare_lower_c[0] = 1'b1; // Initial carry-in for >=
    generate
        genvar i;
        for (i = 0; i < 8; i = i + 1) begin: lower_carry_chain
            assign compare_lower_c[i+1] = compare_lower_g[i] | (compare_lower_p[i] & compare_lower_c[i]);
        end
    endgenerate
    assign greater_equal_lower = compare_lower_c[8];
    
    // Manchester carry chain for upper bound comparison (<=)
    assign compare_upper_c[0] = 1'b1; // Initial carry-in for <=
    generate
        genvar j;
        for (j = 0; j < 8; j = j + 1) begin: upper_carry_chain
            assign compare_upper_c[j+1] = compare_upper_g[j] | (compare_upper_p[j] & compare_upper_c[j]);
        end
    endgenerate
    assign less_equal_upper = compare_upper_c[8];
    
    // Main sequential logic with retimed registers
    always @(posedge clk) begin
        if (rst) begin 
            shift_reg <= 8'b0; 
            bit_count <= 3'b0; 
            greater_equal_lower_reg <= 1'b0;
            less_equal_upper_reg <= 1'b0;
            in_range <= 1'b0; 
        end
        else if (valid) begin
            shift_reg <= {shift_reg[6:0], data_bit};
            bit_count <= bit_count + 1;
            
            // Register the comparison results every cycle
            greater_equal_lower_reg <= greater_equal_lower;
            less_equal_upper_reg <= less_equal_upper;
            
            if (bit_count == 3'b111) // All 8 bits received
                in_range <= greater_equal_lower_reg && less_equal_upper_reg;
        end
    end
endmodule
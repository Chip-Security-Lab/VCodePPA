//SystemVerilog
module conditional_buffer (
    input wire clk,
    input wire [7:0] data_in,
    input wire [7:0] threshold,
    input wire compare_en,
    output reg [7:0] data_out
);
    // Register inputs to reduce input-to-register delay
    reg [7:0] data_in_reg;
    reg [7:0] threshold_reg;
    reg compare_en_reg;
    
    // Optimized comparison logic
    wire unsigned_compare;
    wire compare_equal;
    
    // Register input signals with single always block for better synthesis
    always @(posedge clk) begin
        data_in_reg <= data_in;
        threshold_reg <= threshold;
        compare_en_reg <= compare_en;
    end
    
    // Optimized comparison - split into equality and magnitude tests
    assign compare_equal = (data_in_reg == threshold_reg);
    assign unsigned_compare = (data_in_reg > threshold_reg);
    
    // Output register with complete sensitivity list and reset condition
    always @(posedge clk) begin
        if (compare_en_reg && (unsigned_compare && !compare_equal))
            data_out <= data_in_reg;
        else if (!compare_en_reg)
            data_out <= data_out; // Hold value when comparison disabled
    end
endmodule
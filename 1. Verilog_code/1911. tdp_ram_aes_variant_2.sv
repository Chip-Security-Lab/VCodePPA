//SystemVerilog
module AdaptiveThreshold #(parameter WIDTH=8, ALPHA=3) (
    input clk,
    input [WIDTH-1:0] adc_input,
    output reg digital_out
);
    reg [WIDTH+ALPHA-1:0] avg_level;
    reg [WIDTH-1:0] adc_input_reg;
    wire comp_result;
    
    // Register input
    always @(posedge clk) begin
        adc_input_reg <= adc_input;
    end
    
    // Move comparison before the register
    assign comp_result = adc_input_reg > (avg_level >> ALPHA);
    
    always @(posedge clk) begin
        avg_level <= avg_level + (adc_input_reg - (avg_level >> ALPHA));
        digital_out <= comp_result;
    end
endmodule
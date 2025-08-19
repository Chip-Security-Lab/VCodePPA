module AdaptiveThreshold #(parameter WIDTH=8, ALPHA=3) (
    input clk,
    input [WIDTH-1:0] adc_input,
    output reg digital_out
);
    reg [WIDTH+ALPHA-1:0] avg_level;

    always @(posedge clk) begin
        avg_level <= avg_level + (adc_input - (avg_level >> ALPHA));
        digital_out <= (adc_input > (avg_level >> ALPHA));
    end
endmodule
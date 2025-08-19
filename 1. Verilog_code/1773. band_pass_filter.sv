module band_pass_filter #(
    parameter WIDTH = 12
)(
    input clk, arst,
    input [WIDTH-1:0] x_in,
    output reg [WIDTH-1:0] y_out
);
    reg [WIDTH-1:0] hp_out, lp_out;
    wire [WIDTH-1:0] hp_temp;
    
    // High-pass stage
    assign hp_temp = x_in - lp_out;
    
    always @(posedge clk or posedge arst) begin
        if (arst) begin
            lp_out <= 0; hp_out <= 0; y_out <= 0;
        end else begin
            // Low-pass: alpha = 0.125
            lp_out <= lp_out + ((x_in - lp_out) >>> 3);
            hp_out <= hp_temp;
            // Output is high-passed signal
            y_out <= hp_out;
        end
    end
endmodule
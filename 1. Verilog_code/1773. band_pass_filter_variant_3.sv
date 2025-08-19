//SystemVerilog
module band_pass_filter #(
    parameter WIDTH = 12
)(
    input clk, arst,
    input [WIDTH-1:0] x_in,
    output reg [WIDTH-1:0] y_out
);
    reg [WIDTH-1:0] lp_out, x_in_reg;
    wire [WIDTH-1:0] lp_delta, lp_scaled;
    
    // Pre-compute the low-pass filter delta value
    assign lp_delta = x_in_reg - lp_out;
    
    // Scale the delta (shift right by 3 = divide by 8)
    assign lp_scaled = {3'b0, lp_delta[WIDTH-1:3]};
    
    always @(posedge clk or posedge arst) begin
        if (arst) begin
            lp_out <= 0;
            y_out <= 0;
            x_in_reg <= 0;
        end else begin
            // Register input to break timing path
            x_in_reg <= x_in;
            
            // Low-pass filter update
            lp_out <= lp_out + lp_scaled;
            
            // Output is high-passed signal (x_in - lp_out)
            // Calculate directly instead of using intermediate register
            y_out <= x_in_reg - lp_out;
        end
    end
endmodule
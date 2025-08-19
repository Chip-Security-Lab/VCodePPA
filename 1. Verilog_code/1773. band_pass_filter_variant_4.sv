//SystemVerilog
module band_pass_filter #(
    parameter WIDTH = 12
)(
    input clk, 
    input arst,
    input [WIDTH-1:0] x_in,
    output reg [WIDTH-1:0] y_out
);

    // Pipeline registers for improved timing
    reg [WIDTH-1:0] x_in_reg;
    reg [WIDTH-1:0] lp_out_reg;
    
    // Intermediate signals with clear naming
    wire [WIDTH-1:0] diff_signal;
    wire [WIDTH-1:0] scaled_diff;
    wire [WIDTH-1:0] lp_next;
    wire [WIDTH-1:0] hp_next;
    
    // Input stage - register input for better timing
    always @(posedge clk or posedge arst) begin
        if (arst) begin
            x_in_reg <= 0;
        end else begin
            x_in_reg <= x_in;
        end
    end
    
    // Low-pass calculation stage
    assign diff_signal = x_in_reg - lp_out_reg;
    assign scaled_diff = diff_signal >>> 3;  // alpha = 0.125
    assign lp_next = lp_out_reg + scaled_diff;
    
    // High-pass calculation stage
    assign hp_next = x_in_reg - lp_next;
    
    // Output stage - register outputs
    always @(posedge clk or posedge arst) begin
        if (arst) begin
            lp_out_reg <= 0;
            y_out <= 0;
        end else begin
            lp_out_reg <= lp_next;
            y_out <= hp_next;
        end
    end

endmodule
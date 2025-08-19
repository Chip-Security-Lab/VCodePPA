module data_scrambler #(
    parameter POLY_WIDTH = 16,
    parameter POLYNOMIAL = 16'hA001 // x^16 + x^12 + x^5 + 1
) (
    input wire clk, rst_n,
    input wire data_in,
    input wire scrambled_in,
    input wire bypass_scrambler,
    output reg scrambled_out,
    output reg data_out
);
    reg [POLY_WIDTH-1:0] lfsr_state;
    wire feedback;
    
    // Calculate feedback based on polynomial
    assign feedback = ^(lfsr_state & POLYNOMIAL);
    
    // Scrambler operation
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            lfsr_state <= {POLY_WIDTH{1'b1}}; // Initialize to all 1s
            scrambled_out <= 1'b0;
        end else if (!bypass_scrambler) begin
            // Scramble input data with LFSR output
            scrambled_out <= data_in ^ feedback;
            // Shift LFSR
            lfsr_state <= {lfsr_state[POLY_WIDTH-2:0], feedback};
        end else scrambled_out <= data_in; // Bypass mode
    end
    
    // Descrambler operation (similar to scrambler)
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) data_out <= 1'b0;
        // Descrambler would be implemented here
    end
endmodule
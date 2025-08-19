module data_scrambler #(parameter POLY_WIDTH = 7) (
    input  wire clk,
    input  wire reset,
    input  wire data_in,
    input  wire [POLY_WIDTH-1:0] polynomial,  // Configurable polynomial
    input  wire [POLY_WIDTH-1:0] initial_state,
    input  wire load_init,
    output wire data_out
);
    reg [POLY_WIDTH-1:0] lfsr_reg;
    wire feedback;
    
    // Calculate feedback based on polynomial taps
    assign feedback = ^(lfsr_reg & polynomial);
    
    // Scramble the data by XORing with LFSR output
    assign data_out = data_in ^ lfsr_reg[0];
    
    always @(posedge clk) begin
        if (reset)
            lfsr_reg <= {POLY_WIDTH{1'b1}};  // Non-zero default
        else if (load_init)
            lfsr_reg <= initial_state;
        else
            lfsr_reg <= {feedback, lfsr_reg[POLY_WIDTH-1:1]};
    end
endmodule
module config_poly_lfsr (
    input clock,
    input reset,
    input [15:0] polynomial,  // Configurable taps
    output [15:0] rand_out
);
    reg [15:0] shift_reg;
    wire feedback;
    
    assign feedback = ^(shift_reg & polynomial);
    
    always @(posedge clock) begin
        if (reset)
            shift_reg <= 16'h1;
        else
            shift_reg <= {shift_reg[14:0], feedback};
    end
    
    assign rand_out = shift_reg;
endmodule
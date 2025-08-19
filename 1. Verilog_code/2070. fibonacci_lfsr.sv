module fibonacci_lfsr #(parameter WIDTH = 8) (
    input wire clk, rst_n, enable,
    input wire [WIDTH-1:0] seed,
    input wire [WIDTH-1:0] polynomial,  // Taps as '1' bits
    output wire [WIDTH-1:0] lfsr_out,
    output wire serial_out
);
    reg [WIDTH-1:0] lfsr_reg;
    wire feedback;
    
    // XOR all tapped bits with '1' in polynomial
    assign feedback = ^(lfsr_reg & polynomial);
    assign serial_out = lfsr_reg[0];
    assign lfsr_out = lfsr_reg;
    
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) 
            lfsr_reg <= seed;
        else if (enable)
            lfsr_reg <= {feedback, lfsr_reg[WIDTH-1:1]};
    end
endmodule
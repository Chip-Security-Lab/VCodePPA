module lfsr #(parameter [15:0] POLY = 16'h8016) (
    input wire clock, reset,
    output wire [15:0] lfsr_out,
    output wire sequence_bit
);
    reg [15:0] lfsr_reg;
    wire feedback;
    
    assign feedback = ^(lfsr_reg & POLY);
    
    always @(posedge clock) begin
        if (reset)
            lfsr_reg <= 16'h0001;
        else
            lfsr_reg <= {lfsr_reg[14:0], feedback};
    end
    
    assign lfsr_out = lfsr_reg;
    assign sequence_bit = lfsr_reg[15];
endmodule

module lfsr_sequence_gen #(
    parameter WIDTH = 8,
    parameter [WIDTH-1:0] TAPS = 8'b10111000 // Default polynomial: x^8 + x^6 + x^5 + x^4 + 1
) (
    input  wire clk_i,
    input  wire rst_n,
    input  wire enable,
    input  wire [WIDTH-1:0] seed_i,
    input  wire load_seed,
    output wire [WIDTH-1:0] random_o,
    output wire bit_o
);
    reg [WIDTH-1:0] lfsr_reg;
    wire feedback;
    
    // LFSR feedback calculation based on taps
    assign feedback = ^(lfsr_reg & TAPS);
    assign random_o = lfsr_reg;
    assign bit_o = lfsr_reg[0];
    
    always @(posedge clk_i or negedge rst_n) begin
        if (!rst_n)
            lfsr_reg <= {WIDTH{1'b0}};
        else if (load_seed)
            lfsr_reg <= (seed_i != 0) ? seed_i : {{(WIDTH-1){1'b0}}, 1'b1};
        else if (enable)
            lfsr_reg <= {feedback, lfsr_reg[WIDTH-1:1]};
    end
endmodule
//SystemVerilog
module data_descrambler #(parameter POLY_WIDTH = 7) (
    input  wire clk_in,
    input  wire rst_n,
    input  wire scrambled_in,
    input  wire [POLY_WIDTH-1:0] poly_taps,
    input  wire [POLY_WIDTH-1:0] seed_val,
    input  wire seed_load,
    output wire descrambled_out
);

    // Register declarations
    reg [POLY_WIDTH-1:0] shift_reg;
    reg [POLY_WIDTH-1:0] next_shift_reg;
    
    // Combinational logic
    wire tap_xor;
    assign tap_xor = ^(shift_reg & poly_taps);
    assign descrambled_out = scrambled_in ^ shift_reg[0];
    
    // Next state logic
    always @(*) begin
        if (seed_load)
            next_shift_reg = seed_val;
        else
            next_shift_reg = {tap_xor, shift_reg[POLY_WIDTH-1:1]};
    end
    
    // Sequential logic
    always @(posedge clk_in or negedge rst_n) begin
        if (!rst_n)
            shift_reg <= {POLY_WIDTH{1'b1}};
        else
            shift_reg <= next_shift_reg;
    end

endmodule
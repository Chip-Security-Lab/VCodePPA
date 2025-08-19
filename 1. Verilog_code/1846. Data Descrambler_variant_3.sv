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
    reg [POLY_WIDTH-1:0] shift_reg;
    wire tap_xor;
    
    // Calculate XOR of all tapped bits
    assign tap_xor = ^(shift_reg & poly_taps);
    
    // Descramble data by XORing input with tap output
    assign descrambled_out = scrambled_in ^ shift_reg[0];
    
    always @(posedge clk_in or negedge rst_n) begin
        if (!rst_n)
            shift_reg <= {POLY_WIDTH{1'b1}};
        else begin
            case ({rst_n, seed_load})
                2'b11: shift_reg <= seed_val;
                2'b10: shift_reg <= {tap_xor, shift_reg[POLY_WIDTH-1:1]};
                default: shift_reg <= {POLY_WIDTH{1'b1}}; // 冗余状态保护
            endcase
        end
    end
endmodule
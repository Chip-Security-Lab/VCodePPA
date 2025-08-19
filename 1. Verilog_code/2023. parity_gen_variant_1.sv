//SystemVerilog
module parity_gen #(parameter TYPE = 0) ( // 0: Even, 1: Odd
    input  [7:0] data,
    output       parity
);
    wire xor_01, xor_23, xor_45, xor_67;
    wire xor_0123, xor_4567;
    wire data_xor;
    wire is_odd_type;
    wire is_even_type;
    wire odd_parity;
    wire even_parity;

    // Decompose the XOR tree for better PPA and clarity
    assign xor_01   = data[0] ^ data[1];
    assign xor_23   = data[2] ^ data[3];
    assign xor_45   = data[4] ^ data[5];
    assign xor_67   = data[6] ^ data[7];

    assign xor_0123 = xor_01 ^ xor_23;
    assign xor_4567 = xor_45 ^ xor_67;

    assign data_xor = xor_0123 ^ xor_4567;

    // Control logic decomposition
    assign is_odd_type  = (TYPE == 1'b1);
    assign is_even_type = (TYPE == 1'b0);

    assign odd_parity  = ~data_xor;
    assign even_parity =  data_xor;

    assign parity = is_odd_type ? odd_parity :
                    is_even_type ? even_parity : 1'bx;

endmodule
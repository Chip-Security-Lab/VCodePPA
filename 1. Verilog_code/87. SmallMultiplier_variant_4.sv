//SystemVerilog
// Top-level module
module SmallMultiplier(
    input [1:0] a, b,
    output [3:0] prod
);

    // Partial product generation
    wire [3:0] partial_prod_0, partial_prod_1;
    PartialProductGen ppg0(
        .a(a),
        .b(b[0]),
        .prod(partial_prod_0)
    );
    
    PartialProductGen ppg1(
        .a(a),
        .b(b[1]),
        .prod(partial_prod_1)
    );

    // Final product computation
    ProductAdder pa(
        .partial_prod_0(partial_prod_0),
        .partial_prod_1(partial_prod_1),
        .final_prod(prod)
    );

endmodule

// Partial product generation module
module PartialProductGen(
    input [1:0] a,
    input b,
    output reg [3:0] prod
);
    always @(*) begin
        case({a, b})
            3'b000: prod = 0;
            3'b001: prod = 0;
            3'b010: prod = 0;
            3'b011: prod = 0;
            3'b100: prod = 0;
            3'b101: prod = 1;
            3'b110: prod = 2;
            3'b111: prod = 3;
        endcase
    end
endmodule

// Product addition module
module ProductAdder(
    input [3:0] partial_prod_0,
    input [3:0] partial_prod_1,
    output [3:0] final_prod
);
    assign final_prod = partial_prod_0 + (partial_prod_1 << 1);
endmodule
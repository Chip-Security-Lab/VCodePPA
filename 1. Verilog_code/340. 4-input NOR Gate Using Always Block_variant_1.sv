//SystemVerilog
// Top-level module: Hierarchical NOR4 Booth Multiplier
module nor4_always (
    input  wire [7:0] A,
    input  wire [7:0] B,
    input  wire [7:0] C,
    input  wire [7:0] D,
    output wire [15:0] Y
);
    wire [7:0] nor_out;
    wire [15:0] booth_out;

    // NOR4 Logic Submodule
    nor4_unit u_nor4_unit (
        .in_a(A),
        .in_b(B),
        .in_c(C),
        .in_d(D),
        .nor_result(nor_out)
    );

    // Booth Multiplier Submodule
    booth_multiplier_8bit u_booth_multiplier_8bit (
        .multiplicand(nor_out),
        .multiplier(8'b1),
        .product(booth_out)
    );

    // Output Assignment Unit
    assign Y = booth_out;

endmodule

//-----------------------------------------------------------------------------
// Submodule: NOR4 Logic Unit
// Performs bitwise NOR operation on four 8-bit inputs
//-----------------------------------------------------------------------------
module nor4_unit (
    input  wire [7:0] in_a,
    input  wire [7:0] in_b,
    input  wire [7:0] in_c,
    input  wire [7:0] in_d,
    output wire [7:0] nor_result
);
    assign nor_result = ~(in_a | in_b | in_c | in_d);
endmodule

//-----------------------------------------------------------------------------
// Submodule: Booth Multiplier 8-bit
// Parameterized 8-bit Booth multiplier
//-----------------------------------------------------------------------------
module booth_multiplier_8bit #(
    parameter WIDTH = 8
)(
    input  wire [WIDTH-1:0] multiplicand,
    input  wire [WIDTH-1:0] multiplier,
    output reg  [(2*WIDTH)-1:0] product
);
    reg [(2*WIDTH)-1:0] mcand_ext;
    reg [(2*WIDTH)+1:0] acc;
    integer i;

    always @(*) begin
        mcand_ext = {{WIDTH{multiplicand[WIDTH-1]}}, multiplicand};
        acc = {{WIDTH{1'b0}}, multiplier, 1'b0};
        for (i = 0; i < WIDTH; i = i + 1) begin
            case (acc[1:0])
                2'b01: acc[(2*WIDTH)+1:WIDTH+1] = acc[(2*WIDTH)+1:WIDTH+1] + mcand_ext;
                2'b10: acc[(2*WIDTH)+1:WIDTH+1] = acc[(2*WIDTH)+1:WIDTH+1] - mcand_ext;
                default: ;
            endcase
            acc = {acc[(2*WIDTH)+1], acc[(2*WIDTH)+1:1]};
        end
        product = acc[(2*WIDTH)+1:1];
    end
endmodule
//SystemVerilog
module async_iir_filter #(
    parameter DW = 14
)(
    input [DW-1:0] x_in,
    input [DW-1:0] y_prev,
    input [DW-1:0] a_coeff, b_coeff,
    output [DW-1:0] y_out
);
    // Internal signals for shift-add multipliers
    wire [2*DW-1:0] prod1, prod2;
    
    // Instantiate shift-add multipliers
    shift_add_multiplier #(.WIDTH(DW)) mult1 (
        .a(a_coeff),
        .b(x_in),
        .product(prod1)
    );
    
    shift_add_multiplier #(.WIDTH(DW)) mult2 (
        .a(b_coeff),
        .b(y_prev),
        .product(prod2)
    );
    
    // Final output calculation
    assign y_out = prod1[2*DW-1:DW] + prod2[2*DW-1:DW];
endmodule

module shift_add_multiplier #(
    parameter WIDTH = 14
)(
    input [WIDTH-1:0] a,
    input [WIDTH-1:0] b,
    output [2*WIDTH-1:0] product
);
    // Internal registers
    reg [2*WIDTH-1:0] result;
    reg [WIDTH-1:0] multiplier;
    reg [2*WIDTH-1:0] multiplicand_shifted;
    integer i;
    
    // Combinational shift-add multiplication algorithm
    always @(*) begin
        result = 0;
        multiplier = b;
        multiplicand_shifted = {{WIDTH{1'b0}}, a};
        
        for (i = 0; i < WIDTH; i = i + 1) begin
            if (multiplier[0])
                result = result + multiplicand_shifted;
            
            multiplier = multiplier >> 1;
            multiplicand_shifted = multiplicand_shifted << 1;
        end
    end
    
    // Output assignment
    assign product = result;
endmodule
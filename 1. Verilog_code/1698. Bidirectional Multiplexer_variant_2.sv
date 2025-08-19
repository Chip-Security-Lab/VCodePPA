//SystemVerilog
module karatsuba_multiplier #(
    parameter WIDTH = 8
) (
    input [WIDTH-1:0] a,
    input [WIDTH-1:0] b,
    output [2*WIDTH-1:0] result
);

    generate
        if (WIDTH == 1) begin
            assign result = a * b;
        end
        else begin
            localparam HALF_WIDTH = WIDTH/2;
            wire [HALF_WIDTH-1:0] a_high = a[WIDTH-1:HALF_WIDTH];
            wire [HALF_WIDTH-1:0] a_low = a[HALF_WIDTH-1:0];
            wire [HALF_WIDTH-1:0] b_high = b[WIDTH-1:HALF_WIDTH];
            wire [HALF_WIDTH-1:0] b_low = b[HALF_WIDTH-1:0];
            
            wire [2*HALF_WIDTH-1:0] z0, z1, z2;
            wire [HALF_WIDTH-1:0] a_sum = a_high + a_low;
            wire [HALF_WIDTH-1:0] b_sum = b_high + b_low;
            
            karatsuba_multiplier #(HALF_WIDTH) mult_z0 (
                .a(a_low),
                .b(b_low),
                .result(z0)
            );
            
            karatsuba_multiplier #(HALF_WIDTH) mult_z1 (
                .a(a_sum),
                .b(b_sum),
                .result(z1)
            );
            
            karatsuba_multiplier #(HALF_WIDTH) mult_z2 (
                .a(a_high),
                .b(b_high),
                .result(z2)
            );
            
            wire [2*WIDTH-1:0] z0_shifted = z0;
            wire [2*WIDTH-1:0] z1_shifted = z1 << HALF_WIDTH;
            wire [2*WIDTH-1:0] z2_shifted = z2 << WIDTH;
            
            assign result = z2_shifted + (z1_shifted - z0_shifted - z2_shifted) + z0_shifted;
        end
    endgenerate
endmodule

module bidir_mux(
    inout [7:0] port_a, port_b,
    input direction,
    input enable
);
    reg [7:0] port_a_reg, port_b_reg;
    wire [15:0] mult_result;
    
    karatsuba_multiplier #(8) multiplier (
        .a(port_a),
        .b(port_b),
        .result(mult_result)
    );
    
    always @(*) begin
        port_a_reg = (!enable || direction) ? 8'bz : port_b;
        port_b_reg = (!enable || !direction) ? 8'bz : port_a;
    end
    
    assign port_a = port_a_reg;
    assign port_b = port_b_reg;
endmodule
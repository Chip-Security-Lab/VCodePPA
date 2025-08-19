module parametric_adder #(parameter WIDTH=8)(
    input [WIDTH-1:0] a,
    input [WIDTH-1:0] b,
    output [WIDTH-1:0] sum,
    output cout
);

    wire [WIDTH:0] carry;
    wire [WIDTH-1:0] g, p;
    
    // Generate and propagate signals
    genvar i;
    generate
        for(i = 0; i < WIDTH; i = i + 1) begin: gen_prop
            assign g[i] = a[i] & b[i];
            assign p[i] = a[i] ^ b[i];
        end
    endgenerate
    
    // Carry lookahead logic
    assign carry[0] = 1'b0;
    genvar j;
    generate
        for(j = 0; j < WIDTH; j = j + 1) begin: carry_lookahead
            assign carry[j+1] = g[j] | (p[j] & carry[j]);
        end
    endgenerate
    
    // Sum calculation
    genvar k;
    generate
        for(k = 0; k < WIDTH; k = k + 1) begin: sum_calc
            assign sum[k] = p[k] ^ carry[k];
        end
    endgenerate
    
    assign cout = carry[WIDTH];

endmodule
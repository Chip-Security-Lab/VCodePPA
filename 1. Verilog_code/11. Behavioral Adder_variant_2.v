module behavioral_adder(
    input [7:0] a,
    input [7:0] b,
    output [7:0] sum,
    output cout
);

    wire [8:0] full_sum;
    
    adder_core u_adder_core(
        .a(a),
        .b(b),
        .full_sum(full_sum)
    );
    
    output_formatter u_output_formatter(
        .full_sum(full_sum),
        .sum(sum),
        .cout(cout)
    );

endmodule

module adder_core(
    input [7:0] a,
    input [7:0] b,
    output [8:0] full_sum
);

    parameter WIDTH = 8;
    
    wire [WIDTH:0] carry_chain;
    wire [WIDTH-1:0] sum_bits;
    wire [WIDTH-1:0] g, p;
    
    genvar i;
    generate
        for(i = 0; i < WIDTH; i = i + 1) begin: carry_gen
            assign g[i] = a[i] & b[i];
            assign p[i] = a[i] | b[i];
            
            if(i == 0)
                assign carry_chain[0] = 1'b0;
            else
                assign carry_chain[i] = g[i-1] | (p[i-1] & carry_chain[i-1]);
        end
    endgenerate
    
    genvar j;
    generate
        for(j = 0; j < WIDTH; j = j + 1) begin: sum_gen
            assign sum_bits[j] = a[j] ^ b[j] ^ carry_chain[j];
        end
    endgenerate
    
    assign full_sum = {carry_chain[WIDTH], sum_bits};

endmodule

module output_formatter(
    input [8:0] full_sum,
    output [7:0] sum,
    output cout
);

    assign sum = full_sum[7:0];
    assign cout = full_sum[8];

endmodule
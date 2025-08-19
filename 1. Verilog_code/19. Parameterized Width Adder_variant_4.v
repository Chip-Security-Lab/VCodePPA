module brent_kung_adder #(parameter WIDTH=8)(
    input [WIDTH-1:0] a,
    input [WIDTH-1:0] b,
    output [WIDTH-1:0] sum,
    output cout
);

    // Generate and propagate signals
    wire [WIDTH-1:0] g, p;
    
    // First level - Generate and Propagate
    genvar i;
    generate
        for(i = 0; i < WIDTH; i = i + 1) begin: gen_prop
            assign g[i] = a[i] & b[i];
            assign p[i] = a[i] ^ b[i];
        end
    endgenerate

    // Brent-Kung parallel prefix computation
    wire [WIDTH-1:0] g_level1, p_level1;
    wire [WIDTH-1:0] g_level2, p_level2;
    wire [WIDTH-1:0] g_level3, p_level3;
    wire [WIDTH-1:0] g_level4, p_level4;

    // Level 1 - Black cells
    assign g_level1[0] = g[0];
    assign p_level1[0] = p[0];
    generate
        for(i = 1; i < WIDTH; i = i + 1) begin: level1
            assign g_level1[i] = g[i] | (p[i] & g[i-1]);
            assign p_level1[i] = p[i] & p[i-1];
        end
    endgenerate

    // Level 2 - Black cells
    assign g_level2[0] = g_level1[0];
    assign p_level2[0] = p_level1[0];
    assign g_level2[1] = g_level1[1];
    assign p_level2[1] = p_level1[1];
    generate
        for(i = 2; i < WIDTH; i = i + 2) begin: level2
            assign g_level2[i] = g_level1[i] | (p_level1[i] & g_level1[i-1]);
            assign p_level2[i] = p_level1[i] & p_level1[i-1];
            if(i+1 < WIDTH) begin
                assign g_level2[i+1] = g_level1[i+1] | (p_level1[i+1] & g_level1[i]);
                assign p_level2[i+1] = p_level1[i+1] & p_level1[i];
            end
        end
    endgenerate

    // Level 3 - Black cells
    assign g_level3[0] = g_level2[0];
    assign p_level3[0] = p_level2[0];
    generate
        for(i = 1; i < WIDTH; i = i + 1) begin: level3
            assign g_level3[i] = g_level2[i] | (p_level2[i] & g_level2[i-1]);
            assign p_level3[i] = p_level2[i] & p_level2[i-1];
        end
    endgenerate

    // Level 4 - Black cells
    assign g_level4[0] = g_level3[0];
    assign p_level4[0] = p_level3[0];
    generate
        for(i = 1; i < WIDTH; i = i + 1) begin: level4
            assign g_level4[i] = g_level3[i] | (p_level3[i] & g_level3[i-1]);
            assign p_level4[i] = p_level3[i] & p_level3[i-1];
        end
    endgenerate

    // Final carry computation
    wire [WIDTH-1:0] carry;
    assign carry[0] = 0;
    generate
        for(i = 1; i < WIDTH; i = i + 1) begin: final_carry
            assign carry[i] = g_level4[i-1];
        end
    endgenerate

    // Generate sum and cout
    assign sum = p ^ carry;
    assign cout = g_level4[WIDTH-1];

endmodule
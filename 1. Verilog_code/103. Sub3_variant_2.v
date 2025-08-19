module Sub3 #(parameter W=4)(input [W-1:0] a,b, output [W-1:0] res);
    // Generate and propagate signals
    wire [W-1:0] g, p;
    wire [W-1:0] carry;
    
    // Generate and propagate computation
    genvar i;
    generate
        for(i=0; i<W; i=i+1) begin: gen_prop
            assign g[i] = ~a[i] & b[i];
            assign p[i] = a[i] ^ b[i];
        end
    endgenerate
    
    // Parallel prefix computation
    wire [W-1:0] g_level1, p_level1;
    wire [W-1:0] g_level2, p_level2;
    
    // Level 1
    assign g_level1[0] = g[0];
    assign p_level1[0] = p[0];
    generate
        for(i=1; i<W; i=i+1) begin: level1
            assign g_level1[i] = g[i] | (p[i] & g[i-1]);
            assign p_level1[i] = p[i] & p[i-1];
        end
    endgenerate
    
    // Level 2
    assign g_level2[0] = g_level1[0];
    assign p_level2[0] = p_level1[0];
    generate
        for(i=1; i<W; i=i+1) begin: level2
            assign g_level2[i] = g_level1[i] | (p_level1[i] & g_level1[i-1]);
            assign p_level2[i] = p_level1[i] & p_level1[i-1];
        end
    endgenerate
    
    // Carry computation
    assign carry[0] = 1'b1;
    generate
        for(i=1; i<W; i=i+1) begin: carry_gen
            assign carry[i] = g_level2[i-1] | (p_level2[i-1] & carry[0]);
        end
    endgenerate
    
    // Result computation
    generate
        for(i=0; i<W; i=i+1) begin: result
            assign res[i] = p[i] ^ carry[i];
        end
    endgenerate
endmodule
module Sub3 #(parameter W=8)(
    input [W-1:0] a,
    input [W-1:0] b,
    output [W-1:0] res
);

    // Stage 1: Generate and propagate signals
    wire [W-1:0] g, p;
    wire [W-1:0] sum_stage1;
    
    genvar i;
    generate
        for(i=0; i<W; i=i+1) begin: gen_prop
            assign g[i] = a[i] & ~b[i];
            assign p[i] = a[i] ^ b[i];
            assign sum_stage1[i] = p[i];
        end
    endgenerate
    
    // Stage 2: Conditional sum computation
    wire [W-1:0] sum_stage2;
    wire [W-1:0] carry_cond;
    
    assign carry_cond[0] = g[0];
    generate
        for(i=1; i<W; i=i+1) begin: cond_sum
            assign carry_cond[i] = g[i] | (p[i] & carry_cond[i-1]);
            assign sum_stage2[i] = sum_stage1[i] ^ carry_cond[i-1];
        end
    endgenerate
    assign sum_stage2[0] = sum_stage1[0];
    
    // Final result
    assign res = sum_stage2;
    
endmodule
//SystemVerilog
module not_gate_generate (
    input wire [3:0] A,
    output wire [3:0] Y
);
    wire [3:0] p_gen;
    wire [3:0] g_gen;
    wire [3:0] p_stage1, g_stage1;
    wire [3:0] p_stage2, g_stage2;
    
    assign p_gen = A;
    assign g_gen = 4'b0000;
    assign p_stage1 = p_gen;
    assign g_stage2 = g_gen;
    
    genvar i;
    generate
        for (i = 0; i < 4; i = i + 1) begin : hc_stage
            assign g_stage2[i] = (i > 0) ? (g_stage1[i] | (p_stage1[i] & g_stage1[i-1])) : g_stage1[i];
        end
    endgenerate
    
    generate
        for (i = 0; i < 4; i = i + 1) begin : not_gen
            assign Y[i] = ~p_stage2[i];
        end
    endgenerate
endmodule
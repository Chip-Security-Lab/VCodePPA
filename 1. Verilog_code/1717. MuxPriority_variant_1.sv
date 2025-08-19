//SystemVerilog
module HanCarlsonAdder #(parameter W=8) (
    input [W-1:0] a,
    input [W-1:0] b,
    input cin,
    output [W-1:0] sum,
    output cout
);
    wire [W-1:0] g, p;
    wire [W-1:0] g_level1, p_level1;
    wire [W-1:0] g_level2, p_level2;
    wire [W-1:0] g_level3, p_level3;
    wire [W-1:0] c;

    // Generate and Propagate
    genvar i;
    generate
        for (i = 0; i < W; i = i + 1) begin
            assign g[i] = a[i] & b[i];
            assign p[i] = a[i] ^ b[i];
        end
    endgenerate

    // Level 1: 2-bit groups
    assign g_level1[0] = g[0];
    assign p_level1[0] = p[0];
    generate
        for (i = 1; i < W; i = i + 1) begin
            assign g_level1[i] = g[i] | (p[i] & g[i-1]);
            assign p_level1[i] = p[i] & p[i-1];
        end
    endgenerate

    // Level 2: 4-bit groups
    assign g_level2[0] = g_level1[0];
    assign p_level2[0] = p_level1[0];
    assign g_level2[1] = g_level1[1];
    assign p_level2[1] = p_level1[1];
    generate
        for (i = 2; i < W; i = i + 1) begin
            assign g_level2[i] = g_level1[i] | (p_level1[i] & g_level1[i-2]);
            assign p_level2[i] = p_level1[i] & p_level1[i-2];
        end
    endgenerate

    // Level 3: 8-bit groups
    assign g_level3[0] = g_level2[0];
    assign p_level3[0] = p_level2[0];
    assign g_level3[1] = g_level2[1];
    assign p_level3[1] = p_level2[1];
    assign g_level3[2] = g_level2[2];
    assign p_level3[2] = p_level2[2];
    assign g_level3[3] = g_level2[3];
    assign p_level3[3] = p_level2[3];
    generate
        for (i = 4; i < W; i = i + 1) begin
            assign g_level3[i] = g_level2[i] | (p_level2[i] & g_level2[i-4]);
            assign p_level3[i] = p_level2[i] & p_level2[i-4];
        end
    endgenerate

    // Carry generation
    assign c[0] = cin;
    generate
        for (i = 1; i < W; i = i + 1) begin
            assign c[i] = g_level3[i-1] | (p_level3[i-1] & cin);
        end
    endgenerate

    // Sum generation
    generate
        for (i = 0; i < W; i = i + 1) begin
            assign sum[i] = p[i] ^ c[i];
        end
    endgenerate

    assign cout = g_level3[W-1] | (p_level3[W-1] & cin);
endmodule

module MuxPriority #(parameter W=8, N=4) (
    input [N-1:0] valid,
    input [W-1:0] data [0:N-1],
    output reg [W-1:0] result
);
    wire [N-1:0] valid_priority;
    wire [W-1:0] mux_out [0:N-1];
    wire [W-1:0] temp_sum;
    wire cout;
    
    // Priority encoder
    assign valid_priority[0] = valid[0];
    genvar i;
    generate
        for (i = 1; i < N; i = i + 1) begin
            assign valid_priority[i] = valid[i] & ~(|valid[i-1:0]);
        end
    endgenerate
    
    // Multiplexer
    genvar j;
    generate
        for (j = 0; j < N; j = j + 1) begin
            assign mux_out[j] = valid_priority[j] ? data[j] : {W{1'b0}};
        end
    endgenerate
    
    // Han-Carlson Adder for final OR reduction
    HanCarlsonAdder #(.W(W)) adder_inst (
        .a(mux_out[0]),
        .b(mux_out[1]),
        .cin(1'b0),
        .sum(temp_sum),
        .cout(cout)
    );
    
    always @(*) begin
        result = temp_sum;
        for (integer k = 2; k < N; k = k + 1) begin
            result = result | mux_out[k];
        end
    end
endmodule
module TwoCompSub(input signed [7:0] a, b, output signed [7:0] res);
    wire [7:0] b_comp;
    wire [7:0] sum;
    wire [7:0] carry;
    wire [7:0] gen, prop;
    
    // 计算b的补码
    assign b_comp = ~b + 1'b1;
    
    // 预计算生成和传播信号
    genvar i;
    generate
        for (i = 0; i < 8; i = i + 1) begin : precompute
            assign gen[i] = a[i] & b_comp[i];
            assign prop[i] = a[i] ^ b_comp[i];
        end
    endgenerate
    
    // 优化进位链
    assign carry[0] = gen[0];
    generate
        for (i = 1; i < 8; i = i + 1) begin : carry_chain
            assign carry[i] = gen[i] | (prop[i] & carry[i-1]);
        end
    endgenerate
    
    // 计算最终和
    assign sum[0] = prop[0];
    generate
        for (i = 1; i < 8; i = i + 1) begin : sum_compute
            assign sum[i] = prop[i] ^ carry[i-1];
        end
    endgenerate
    
    assign res = sum;
endmodule
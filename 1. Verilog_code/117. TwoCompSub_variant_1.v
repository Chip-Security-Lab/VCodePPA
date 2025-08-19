module TwoCompSub(input signed [7:0] a, b, output signed [7:0] res);
    wire [7:0] b_comp;
    wire [7:0] carry;
    wire [7:0] sum;
    
    // 优化补码计算 - 使用德摩根定律简化
    assign b_comp = ~b + 1'b1;
    
    // 优化进位链加法器 - 使用超前进位技术
    assign carry[0] = a[0] & b_comp[0];
    assign sum[0] = a[0] ^ b_comp[0];
    
    genvar i;
    generate
        for(i = 1; i < 8; i = i + 1) begin : carry_lookahead_adder
            wire g = a[i] & b_comp[i];
            wire p = a[i] ^ b_comp[i];
            assign carry[i] = g | (p & carry[i-1]);
            assign sum[i] = p ^ carry[i-1];
        end
    endgenerate
    
    assign res = sum;
endmodule
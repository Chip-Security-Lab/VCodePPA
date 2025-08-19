//SystemVerilog
module signed_multiply_subtract_req_ack (
    input clk,
    input rst_n,
    input signed [7:0] a,
    input signed [7:0] b,
    input signed [7:0] c,
    input req,                    // 请求信号，替代valid
    output reg ack,               // 应答信号，替代ready
    output reg signed [15:0] result
);
    // 内部寄存器和信号
    reg processing;
    wire signed [15:0] comb_result;
    
    // 调用原始的组合逻辑模块
    signed_multiply_subtract core_logic (
        .a(a),
        .b(b),
        .c(c),
        .result(comb_result)
    );
    
    // 请求-应答控制逻辑
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            ack <= 1'b0;
            processing <= 1'b0;
            result <= 16'b0;
        end
        else begin
            if (req && !processing) begin
                // 接收到新请求
                processing <= 1'b1;
                result <= comb_result;
                ack <= 1'b1;
            end
            else if (processing && ack) begin
                // 完成应答周期
                ack <= 1'b0;
                processing <= 1'b0;
            end
        end
    end
    
endmodule

// 原始的组合逻辑模块保持不变
module signed_multiply_subtract (
    input signed [7:0] a,
    input signed [7:0] b,
    input signed [7:0] c,
    output signed [15:0] result
);
    // Wallace树乘法器的部分积生成
    wire signed [15:0] pp [0:7];
    wire signed [15:0] mult_result;
    wire signed [15:0] extended_c;
    
    // 生成部分积
    assign pp[0] = b[0] ? {{8{a[7]}}, a} : 16'b0;
    assign pp[1] = b[1] ? {{7{a[7]}}, a, 1'b0} : 16'b0;
    assign pp[2] = b[2] ? {{6{a[7]}}, a, 2'b0} : 16'b0;
    assign pp[3] = b[3] ? {{5{a[7]}}, a, 3'b0} : 16'b0;
    assign pp[4] = b[4] ? {{4{a[7]}}, a, 4'b0} : 16'b0;
    assign pp[5] = b[5] ? {{3{a[7]}}, a, 5'b0} : 16'b0;
    assign pp[6] = b[6] ? {{2{a[7]}}, a, 6'b0} : 16'b0;
    assign pp[7] = b[7] ? {{1{a[7]}}, a, 7'b0} : 16'b0;
    
    // Wallace树第一级 - 将8个部分积压缩成6个
    wire signed [15:0] s1_0, c1_0;
    wire signed [15:0] s1_1, c1_1;
    
    full_adder_16bit fa1_0 (pp[0], pp[1], pp[2], s1_0, c1_0);
    full_adder_16bit fa1_1 (pp[3], pp[4], pp[5], s1_1, c1_1);
    
    // Wallace树第二级 - 将6个部分积压缩成4个
    wire signed [15:0] s2_0, c2_0;
    wire signed [15:0] s2_1, c2_1;
    
    full_adder_16bit fa2_0 (s1_0, c1_0, s1_1, s2_0, c2_0);
    full_adder_16bit fa2_1 (c1_1, pp[6], pp[7], s2_1, c2_1);
    
    // Wallace树第三级 - 将4个部分积压缩成2个
    wire signed [15:0] s3_0, c3_0;
    
    full_adder_16bit fa3_0 (s2_0, c2_0, s2_1, s3_0, c3_0);
    
    // 最终加法 - 将剩余的2个部分积相加得到乘法结果
    assign mult_result = s3_0 + c3_0 + c2_1;
    
    // 减法操作
    assign extended_c = {{8{c[7]}}, c};
    assign result = mult_result - extended_c;
    
endmodule

// 16位全加器模块 (压缩3个输入为2个输出)
module full_adder_16bit (
    input signed [15:0] a,
    input signed [15:0] b,
    input signed [15:0] c,
    output signed [15:0] sum,
    output signed [15:0] carry
);
    assign sum = a ^ b ^ c;
    assign carry = ((a & b) | (b & c) | (a & c)) << 1;
endmodule
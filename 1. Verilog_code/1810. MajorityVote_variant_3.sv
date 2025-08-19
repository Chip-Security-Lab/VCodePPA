//SystemVerilog
module MajorityVote #(parameter N=5, M=3) (
    input [N-1:0] inputs,
    output reg vote_out
);
    // 使用曼彻斯特进位链加法器实现计数
    // 定义内部信号
    wire [7:0] count_result;
    wire [N-1:0] input_ext; // 扩展为8位
    
    // 将输入扩展到8位宽度
    assign input_ext = inputs;
    
    // 曼彻斯特进位链加法器实现
    wire [7:0] p; // 生成信号
    wire [7:0] g; // 传播信号
    wire [8:0] c; // 进位信号，多一位
    
    // 初始生成和传播信号
    genvar j;
    generate
        for (j = 0; j < N; j = j + 1) begin: gen_pg_init
            assign p[j] = input_ext[j];
            assign g[j] = 1'b0;
        end
        
        for (j = N; j < 8; j = j + 1) begin: gen_pg_zeros
            assign p[j] = 1'b0;
            assign g[j] = 1'b0;
        end
    endgenerate
    
    // 初始进位为0
    assign c[0] = 1'b0;
    
    // 曼彻斯特进位链计算
    generate
        for (j = 0; j < 8; j = j + 1) begin: gen_carry
            assign c[j+1] = g[j] | (p[j] & c[j]);
        end
    endgenerate
    
    // 计算和
    generate
        for (j = 0; j < 8; j = j + 1) begin: gen_sum
            assign count_result[j] = p[j] ^ c[j];
        end
    endgenerate
    
    // 判断多数表决结果
    always @(*) begin
        vote_out = (count_result >= M);
    end
endmodule
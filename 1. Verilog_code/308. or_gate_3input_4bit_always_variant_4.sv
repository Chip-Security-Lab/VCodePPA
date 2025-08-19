//SystemVerilog
// 顶层模块 - 三输入4位加法器
module or_gate_3input_4bit_always (
    input wire [3:0] a,
    input wire [3:0] b,
    input wire [3:0] c,
    output wire [3:0] y
);
    // 使用优化的加法器直接完成三输入加法
    optimized_3input_adder_4bit adder (
        .a(a),
        .b(b),
        .c(c),
        .sum(y)
    );
endmodule

// 优化的三输入4位加法器
module optimized_3input_adder_4bit (
    input wire [3:0] a,
    input wire [3:0] b,
    input wire [3:0] c,
    output wire [3:0] sum
);
    // 内部信号声明
    wire [3:0] p1, p2, g1, g2;
    wire [3:0] ab_xor;
    wire [4:0] carries;
    
    // 第一级传播和生成逻辑
    assign ab_xor = a ^ b;
    assign p1 = ab_xor;         // 传播 = a XOR b
    assign g1 = a & b;          // 生成 = a AND b
    
    // 第二级传播和生成逻辑
    assign p2 = ab_xor ^ c;     // 第二级传播
    assign g2 = (ab_xor & c) | g1; // 优化的第二级生成
    
    // 简化的进位链
    assign carries[0] = 1'b0;
    
    // 优化的进位逻辑，减少逻辑深度
    genvar i;
    generate
        for (i = 0; i < 4; i = i + 1) begin : carry_gen
            if (i == 0) begin
                assign carries[i+1] = g2[i];
            end else begin
                assign carries[i+1] = g2[i] | (p2[i] & carries[i]);
            end
        end
    endgenerate
    
    // 计算最终和
    assign sum = p2 ^ carries[3:0];
endmodule
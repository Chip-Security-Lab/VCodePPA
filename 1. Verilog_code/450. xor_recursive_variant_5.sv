//SystemVerilog
module xor_recursive(
    input [7:0] a, b,
    output [7:0] y
);
    // 优化XOR级联，重新排列以减少关键路径长度和逻辑深度
    // 采用分组策略，减少串行依赖性
    
    // 第一位保持不变
    assign y[0] = a[0] ^ b[0];
    
    // 对其他位应用并行计算与累积
    wire [7:0] ab_xor;
    assign ab_xor = a ^ b;
    
    // 使用分段进位传播策略，降低关键路径延迟
    assign y[1] = ab_xor[1] ^ y[0];
    assign y[2] = ab_xor[2] ^ (ab_xor[1] & y[0]) ^ (ab_xor[1] ^ y[0]);
    assign y[3] = ab_xor[3] ^ (ab_xor[2] & y[1]) ^ (ab_xor[2] ^ y[1]);
    assign y[4] = ab_xor[4] ^ (ab_xor[3] & y[2]) ^ (ab_xor[3] ^ y[2]);
    assign y[5] = ab_xor[5] ^ (ab_xor[4] & y[3]) ^ (ab_xor[4] ^ y[3]);
    assign y[6] = ab_xor[6] ^ (ab_xor[5] & y[4]) ^ (ab_xor[5] ^ y[4]);
    assign y[7] = ab_xor[7] ^ (ab_xor[6] & y[5]) ^ (ab_xor[6] ^ y[5]);
endmodule
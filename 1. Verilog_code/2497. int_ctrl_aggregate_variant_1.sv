//SystemVerilog
//IEEE 1364-2005 Verilog standard
module int_ctrl_aggregate #(
    parameter IN_NUM = 8,
    parameter OUT_NUM = 2
)(
    input [IN_NUM-1:0] intr_in,
    input [OUT_NUM*IN_NUM-1:0] prio_map_flat,
    output reg [OUT_NUM-1:0] intr_out
);
    // 提取prio_map数组
    wire [IN_NUM-1:0] prio_map [0:OUT_NUM-1];
    genvar g;
    generate
        for (g = 0; g < OUT_NUM; g = g + 1) begin: prio_map_gen
            assign prio_map[g] = prio_map_flat[(g+1)*IN_NUM-1:g*IN_NUM];
        end
    endgenerate
    
    // 使用跳跃进位加法器计算中间结果
    wire [OUT_NUM-1:0] intr_result;
    
    generate
        for (g = 0; g < OUT_NUM; g = g + 1) begin: intr_calc
            wire [IN_NUM-1:0] masked_intr;
            wire [7:0] sum_result;
            
            assign masked_intr = intr_in & prio_map[g];
            
            // 跳跃进位加法器实现
            skip_carry_adder sca_inst (
                .a(masked_intr),
                .b(8'b0),
                .req(1'b1),  // 请求信号替代cin
                .sum(sum_result),
                .ack()       // 应答信号替代cout
            );
            
            // 如果sum_result不为0，则有中断
            assign intr_result[g] = |sum_result;
        end
    endgenerate
    
    // 更新输出
    always @* begin
        intr_out = intr_result;
    end
endmodule

// 跳跃进位加法器模块 - 8位
module skip_carry_adder (
    input [7:0] a,
    input [7:0] b,
    input req,        // 请求信号替代cin
    output [7:0] sum,
    output ack        // 应答信号替代cout
);
    wire [1:0] block_ack;   // 替代block_cout
    wire [1:0] block_p;
    
    // 分为2个4位块
    wire [3:0] sum_low, sum_high;
    
    // 第一个4位块的进位传播信号
    wire p0, p1, p2, p3;
    assign p0 = a[0] | b[0];
    assign p1 = a[1] | b[1];
    assign p2 = a[2] | b[2];
    assign p3 = a[3] | b[3];
    assign block_p[0] = p0 & p1 & p2 & p3;
    
    // 第二个4位块的进位传播信号
    wire p4, p5, p6, p7;
    assign p4 = a[4] | b[4];
    assign p5 = a[5] | b[5];
    assign p6 = a[6] | b[6];
    assign p7 = a[7] | b[7];
    assign block_p[1] = p4 & p5 & p6 & p7;
    
    // 第一个4位加法器
    ripple_carry_adder_4bit rca1 (
        .a(a[3:0]),
        .b(b[3:0]),
        .req(req),         // 请求信号替代cin
        .sum(sum_low),
        .ack(block_ack[0]) // 应答信号替代cout
    );
    
    // 跳跃进位逻辑
    wire req_to_high_block; // 替代carry_to_high_block
    assign req_to_high_block = block_p[0] ? req : block_ack[0];
    
    // 第二个4位加法器
    ripple_carry_adder_4bit rca2 (
        .a(a[7:4]),
        .b(b[7:4]),
        .req(req_to_high_block), // 请求信号替代cin
        .sum(sum_high),
        .ack(block_ack[1])       // 应答信号替代cout
    );
    
    // 组合输出
    assign sum = {sum_high, sum_low};
    assign ack = block_ack[1];   // 应答信号替代cout
endmodule

// 4位行波进位加法器
module ripple_carry_adder_4bit (
    input [3:0] a,
    input [3:0] b,
    input req,        // 请求信号替代cin
    output [3:0] sum,
    output ack        // 应答信号替代cout
);
    wire [4:0] req_chain; // 替代c，请求信号链
    assign req_chain[0] = req;
    
    genvar i;
    generate
        for (i = 0; i < 4; i = i + 1) begin: fa_loop
            full_adder fa (
                .a(a[i]),
                .b(b[i]),
                .req(req_chain[i]),    // 请求信号替代cin
                .sum(sum[i]),
                .ack(req_chain[i+1])   // 应答信号替代cout
            );
        end
    endgenerate
    
    assign ack = req_chain[4];  // 应答信号替代cout
endmodule

// 1位全加器
module full_adder (
    input a,
    input b,
    input req,     // 请求信号替代cin
    output sum,
    output ack     // 应答信号替代cout
);
    wire p, g;
    
    assign p = a ^ b;
    assign g = a & b;
    
    assign sum = p ^ req;   // 使用req替代cin
    assign ack = g | (p & req); // 使用req替代cin，ack替代cout
endmodule
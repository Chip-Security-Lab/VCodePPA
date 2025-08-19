//SystemVerilog
module pipelined_crossbar (
    input wire clock, reset,
    input wire [15:0] in0, in1, in2, in3,
    input wire [1:0] sel0, sel1, sel2, sel3,
    output wire [15:0] out0, out1, out2, out3
);
    // Stage 1: Input registration - using arrays for cleaner code
    reg [15:0] in_reg [0:3];
    reg [1:0] sel_reg [0:3];
    
    // Stage 2: Crossbar switching output
    wire [15:0] xbar_out [0:3];
    reg [15:0] xbar_out_reg [0:3]; // 添加寄存器增强流水线
    
    // Stage 3: CLA adder results
    reg [15:0] out_reg [0:3];
    
    // Internal signals for CLA adder
    wire [15:0] cla_sum [0:3];
    
    integer i;
    
    // 流水线寄存器逻辑
    always @(posedge clock) begin
        if (reset) begin
            // 复位逻辑拆分为多个简单条件
            for (i = 0; i < 4; i = i + 1) begin
                in_reg[i] <= 16'h0000;
                sel_reg[i] <= 2'b00;
                xbar_out_reg[i] <= 16'h0000;
                out_reg[i] <= 16'h0000;
            end
        end 
        else begin
            // Pipeline stage 1 - register inputs
            // 拆分为独立赋值以提高可读性
            in_reg[0] <= in0;
            sel_reg[0] <= sel0;
            
            in_reg[1] <= in1;
            sel_reg[1] <= sel1;
            
            in_reg[2] <= in2;
            sel_reg[2] <= sel2;
            
            in_reg[3] <= in3;
            sel_reg[3] <= sel3;
            
            // Pipeline stage 2 - register crossbar output
            for (i = 0; i < 4; i = i + 1) begin
                xbar_out_reg[i] <= xbar_out[i];
            end
            
            // Pipeline stage 3 - register CLA adder results
            for (i = 0; i < 4; i = i + 1) begin
                out_reg[i] <= cla_sum[i];
            end
        end
    end
    
    // Crossbar 选择逻辑 - 拆分为独立模块以提高可读性和PPA
    crossbar_mux mux0 (.sel(sel_reg[0]), .in0(in_reg[0]), .in1(in_reg[1]), .in2(in_reg[2]), .in3(in_reg[3]), .out(xbar_out[0]));
    crossbar_mux mux1 (.sel(sel_reg[1]), .in0(in_reg[0]), .in1(in_reg[1]), .in2(in_reg[2]), .in3(in_reg[3]), .out(xbar_out[1]));
    crossbar_mux mux2 (.sel(sel_reg[2]), .in0(in_reg[0]), .in1(in_reg[1]), .in2(in_reg[2]), .in3(in_reg[3]), .out(xbar_out[2]));
    crossbar_mux mux3 (.sel(sel_reg[3]), .in0(in_reg[0]), .in1(in_reg[1]), .in2(in_reg[2]), .in3(in_reg[3]), .out(xbar_out[3]));
    
    // Instantiate CLA adders - adding 16'h0001 to each output from crossbar
    cla_adder_16bit cla0 (.a(xbar_out_reg[0]), .b(16'h0001), .cin(1'b0), .sum(cla_sum[0]));
    cla_adder_16bit cla1 (.a(xbar_out_reg[1]), .b(16'h0001), .cin(1'b0), .sum(cla_sum[1]));
    cla_adder_16bit cla2 (.a(xbar_out_reg[2]), .b(16'h0001), .cin(1'b0), .sum(cla_sum[2]));
    cla_adder_16bit cla3 (.a(xbar_out_reg[3]), .b(16'h0001), .cin(1'b0), .sum(cla_sum[3]));
    
    // Output assignments
    assign out0 = out_reg[0];
    assign out1 = out_reg[1];
    assign out2 = out_reg[2];
    assign out3 = out_reg[3];
endmodule

// Crossbar 多路复用器模块
module crossbar_mux (
    input wire [1:0] sel,
    input wire [15:0] in0, in1, in2, in3,
    output reg [15:0] out
);
    // 简化条件结构，避免嵌套条件和复杂逻辑
    always @(*) begin
        case (sel)
            2'b00: out = in0;
            2'b01: out = in1;
            2'b10: out = in2;
            2'b11: out = in3;
        endcase
    end
endmodule

// 16-bit Carry Look-Ahead Adder - 优化结构
module cla_adder_16bit (
    input [15:0] a, b,
    input cin,
    output [15:0] sum
);
    // Generate and propagate signals
    wire [15:0] p, g;
    wire [16:0] c;
    
    // First level - calculate propagate and generate
    assign p = a ^ b;
    assign g = a & b;
    
    // 使用CLA逻辑计算每4位一组的进位
    // Block 1 (bits 0-3)
    wire block1_p, block1_g;
    cla_4bit_block cla_block1 (
        .p(p[3:0]),
        .g(g[3:0]),
        .cin(cin),
        .c(c[4:1]),
        .block_p(block1_p),
        .block_g(block1_g)
    );
    
    // Block 2 (bits 4-7)
    wire block2_p, block2_g;
    cla_4bit_block cla_block2 (
        .p(p[7:4]),
        .g(g[7:4]),
        .cin(c[4]),
        .c(c[8:5]),
        .block_p(block2_p),
        .block_g(block2_g)
    );
    
    // Block 3 (bits 8-11)
    wire block3_p, block3_g;
    cla_4bit_block cla_block3 (
        .p(p[11:8]),
        .g(g[11:8]),
        .cin(c[8]),
        .c(c[12:9]),
        .block_p(block3_p),
        .block_g(block3_g)
    );
    
    // Block 4 (bits 12-15)
    wire block4_p, block4_g;
    cla_4bit_block cla_block4 (
        .p(p[15:12]),
        .g(g[15:12]),
        .cin(c[12]),
        .c(c[16:13]),
        .block_p(block4_p),
        .block_g(block4_g)
    );
    
    // 设置初始进位
    assign c[0] = cin;
    
    // Calculate final sum
    assign sum = p ^ c[15:0];
endmodule

// 4位CLA块，用于简化结构
module cla_4bit_block (
    input [3:0] p, g,
    input cin,
    output [4:1] c,
    output block_p, block_g
);
    // 计算各级进位
    assign c[1] = g[0] | (p[0] & cin);
    
    // 中间变量简化第二级进位计算
    wire p0_and_cin = p[0] & cin;
    assign c[2] = g[1] | (p[1] & g[0]) | (p[1] & p0_and_cin);
    
    // 中间变量简化第三级进位计算
    wire p1_and_g0 = p[1] & g[0];
    wire p1_and_p0_and_cin = p[1] & p0_and_cin;
    assign c[3] = g[2] | (p[2] & g[1]) | (p[2] & p1_and_g0) | (p[2] & p1_and_p0_and_cin);
    
    // 中间变量简化第四级进位计算
    wire p2_and_g1 = p[2] & g[1];
    wire p2_and_p1_and_g0 = p[2] & p1_and_g0;
    wire p2_and_p1_and_p0_and_cin = p[2] & p1_and_p0_and_cin;
    assign c[4] = g[3] | (p[3] & g[2]) | (p[3] & p2_and_g1) | 
                 (p[3] & p2_and_p1_and_g0) | (p[3] & p2_and_p1_and_p0_and_cin);
    
    // 计算块级传播和生成信号
    assign block_p = &p;  // p[3] & p[2] & p[1] & p[0]
    assign block_g = g[3] | (p[3] & g[2]) | (p[3] & p[2] & g[1]) | (p[3] & p[2] & p[1] & g[0]);
endmodule
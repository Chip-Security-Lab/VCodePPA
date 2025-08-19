//SystemVerilog
// 顶层模块
module variable_pulse_gen(
    input CLK,
    input RST,
    input [9:0] PULSE_WIDTH,
    input [9:0] PERIOD,
    output PULSE
);
    // 内部连线
    wire [9:0] counter_value;
    
    // 实例化计数器子模块
    counter_module counter_inst (
        .clk(CLK),
        .rst(RST),
        .period(PERIOD),
        .counter_out(counter_value)
    );
    
    // 实例化脉冲生成子模块
    pulse_generator pulse_gen_inst (
        .clk(CLK),
        .rst(RST),
        .counter_value(counter_value),
        .pulse_width(PULSE_WIDTH),
        .pulse_out(PULSE)
    );
    
endmodule

// 计数器子模块
module counter_module (
    input clk,
    input rst,
    input [9:0] period,
    output reg [9:0] counter_out
);
    // 使用Han-Carlson加法器进行计数
    wire [9:0] next_count;
    
    // 实例化Han-Carlson加法器
    han_carlson_adder adder_inst (
        .a(counter_out),
        .b(10'd1),
        .sum(next_count)
    );
    
    // 重置逻辑
    wire [9:0] counter_next;
    assign counter_next = (counter_out >= period) ? 10'd0 : next_count;
    
    always @(posedge clk) begin
        if (rst)
            counter_out <= 10'd0;
        else
            counter_out <= counter_next;
    end
    
endmodule

// Han-Carlson加法器模块
module han_carlson_adder (
    input [9:0] a,
    input [9:0] b,
    output [9:0] sum
);
    // 第一阶段：生成 generate (g) 和 propagate (p) 信号
    wire [9:0] g_init, p_init;
    
    // 生成初始g和p信号
    assign g_init = a & b;
    assign p_init = a ^ b;
    
    // 第二阶段：前缀计算网络 - Han-Carlson加法器
    // 中间进位信号
    wire [9:0] g_s1, p_s1;
    wire [9:0] g_s2, p_s2;
    wire [9:0] g_s3, p_s3;
    wire [9:0] g_s4, p_s4;
    
    // 第一级 - 仅处理偶数位 (Han-Carlson特点)
    assign g_s1[0] = g_init[0];
    assign p_s1[0] = p_init[0];
    
    genvar i;
    generate
        for (i = 2; i < 10; i = i + 2) begin : stage1_even
            assign g_s1[i] = g_init[i] | (p_init[i] & g_init[i-1]);
            assign p_s1[i] = p_init[i] & p_init[i-1];
        end
        
        for (i = 1; i < 10; i = i + 2) begin : stage1_odd
            assign g_s1[i] = g_init[i];
            assign p_s1[i] = p_init[i];
        end
    endgenerate
    
    // 第二级 - 步长为2
    assign g_s2[0] = g_s1[0];
    assign p_s2[0] = p_s1[0];
    assign g_s2[1] = g_s1[1];
    assign p_s2[1] = p_s1[1];
    
    generate
        for (i = 2; i < 10; i = i + 2) begin : stage2_even
            assign g_s2[i] = g_s1[i] | (p_s1[i] & g_s1[i-2]);
            assign p_s2[i] = p_s1[i] & p_s1[i-2];
        end
        
        for (i = 3; i < 10; i = i + 2) begin : stage2_odd
            assign g_s2[i] = g_s1[i];
            assign p_s2[i] = p_s1[i];
        end
    endgenerate
    
    // 第三级 - 步长为4
    assign g_s3[0] = g_s2[0];
    assign p_s3[0] = p_s2[0];
    assign g_s3[1] = g_s2[1];
    assign p_s3[1] = p_s2[1];
    assign g_s3[2] = g_s2[2];
    assign p_s3[2] = p_s2[2];
    assign g_s3[3] = g_s2[3];
    assign p_s3[3] = p_s2[3];
    
    generate
        for (i = 4; i < 10; i = i + 2) begin : stage3_even
            assign g_s3[i] = g_s2[i] | (p_s2[i] & g_s2[i-4]);
            assign p_s3[i] = p_s2[i] & p_s2[i-4];
        end
        
        for (i = 5; i < 10; i = i + 2) begin : stage3_odd
            assign g_s3[i] = g_s2[i];
            assign p_s3[i] = p_s2[i];
        end
    endgenerate
    
    // 第四级 - 步长为8
    assign g_s4[0] = g_s3[0];
    assign p_s4[0] = p_s3[0];
    assign g_s4[1] = g_s3[1];
    assign p_s4[1] = p_s3[1];
    assign g_s4[2] = g_s3[2];
    assign p_s4[2] = p_s3[2];
    assign g_s4[3] = g_s3[3];
    assign p_s4[3] = p_s3[3];
    assign g_s4[4] = g_s3[4];
    assign p_s4[4] = p_s3[4];
    assign g_s4[5] = g_s3[5];
    assign p_s4[5] = p_s3[5];
    assign g_s4[6] = g_s3[6];
    assign p_s4[6] = p_s3[6];
    assign g_s4[7] = g_s3[7];
    assign p_s4[7] = p_s3[7];
    
    generate
        for (i = 8; i < 10; i = i + 2) begin : stage4_even
            assign g_s4[i] = g_s3[i] | (p_s3[i] & g_s3[i-8]);
            assign p_s4[i] = p_s3[i] & p_s3[i-8];
        end
        
        for (i = 9; i < 10; i = i + 2) begin : stage4_odd
            assign g_s4[i] = g_s3[i];
            assign p_s4[i] = p_s3[i];
        end
    endgenerate
    
    // 最后阶段：计算偶数位的进位
    wire [9:0] c;
    assign c[0] = 1'b0; // 第一位没有进位输入
    
    generate
        for (i = 2; i < 10; i = i + 2) begin : carry_even
            assign c[i] = g_s4[i-1];
        end
    endgenerate
    
    // 计算奇数位的进位
    generate
        for (i = 1; i < 10; i = i + 2) begin : carry_odd
            assign c[i] = g_init[i-1] | (p_init[i-1] & c[i-1]);
        end
    endgenerate
    
    // 计算最终和
    assign sum = p_init ^ c;
    
endmodule

// 脉冲生成子模块
module pulse_generator (
    input clk,
    input rst,
    input [9:0] counter_value,
    input [9:0] pulse_width,
    output reg pulse_out
);
    // 优化比较逻辑，使用一个位比较而不是多位比较
    wire pulse_condition;
    
    // 使用范围比较优化
    assign pulse_condition = (counter_value < pulse_width);
    
    always @(posedge clk) begin
        if (rst)
            pulse_out <= 1'b0;
        else
            pulse_out <= pulse_condition;
    end
    
endmodule
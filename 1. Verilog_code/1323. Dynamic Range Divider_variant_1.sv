//SystemVerilog
module dynamic_divider (
    input wire clock,
    input wire reset_b,
    input wire load,
    input wire [7:0] divide_value,
    output reg divided_clock
);
    // 寄存器信号声明
    reg [7:0] divider_reg;
    reg [7:0] counter;
    
    // 组合逻辑信号声明
    wire [7:0] counter_next;
    wire counter_max;
    
    // 组合逻辑：检测计数器是否达到分频值
    assign counter_max = (counter >= divider_reg - 8'h1);
    
    // 实例化并行前缀加法器（纯组合逻辑）
    parallel_prefix_adder adder_inst (
        .a(counter),
        .b(8'h01),
        .sum(counter_next)
    );
    
    // 时序逻辑块
    always @(posedge clock or negedge reset_b) begin
        if (!reset_b) begin
            counter <= 8'h0;
            divider_reg <= 8'h1;
            divided_clock <= 1'b0;
        end 
        else begin
            // 加载新分频值
            if (load) begin
                divider_reg <= divide_value;
            end
            
            // 计数器逻辑
            if (counter_max) begin
                counter <= 8'h0;
                divided_clock <= ~divided_clock;
            end 
            else begin
                counter <= counter_next;
            end
        end
    end
endmodule

// 并行前缀加法器模块 (Kogge-Stone) - 纯组合逻辑
module parallel_prefix_adder (
    input wire [7:0] a,
    input wire [7:0] b,
    output wire [7:0] sum
);
    // 生成和传播信号
    wire [7:0] g_init, p_init;
    
    // 各级生成和传播信号
    wire [7:0] g_l1, p_l1;  // 第1级
    wire [7:0] g_l2, p_l2;  // 第2级
    wire [7:0] g_l3, p_l3;  // 第3级
    wire [7:0] carry;
    
    // 初始生成和传播信号计算
    assign g_init = a & b;                // 生成
    assign p_init = a ^ b;                // 传播
    
    // 第1级: 1位距离
    assign g_l1[0] = g_init[0];
    assign p_l1[0] = p_init[0];
    
    genvar i;
    generate
        for (i = 1; i < 8; i = i + 1) begin : level1
            assign g_l1[i] = g_init[i] | (p_init[i] & g_init[i-1]);
            assign p_l1[i] = p_init[i] & p_init[i-1];
        end
    endgenerate
    
    // 第2级: 2位距离
    assign g_l2[0] = g_l1[0];
    assign p_l2[0] = p_l1[0];
    assign g_l2[1] = g_l1[1];
    assign p_l2[1] = p_l1[1];
    
    generate
        for (i = 2; i < 8; i = i + 1) begin : level2
            assign g_l2[i] = g_l1[i] | (p_l1[i] & g_l1[i-2]);
            assign p_l2[i] = p_l1[i] & p_l1[i-2];
        end
    endgenerate
    
    // 第3级: 4位距离
    assign g_l3[0] = g_l2[0];
    assign p_l3[0] = p_l2[0];
    assign g_l3[1] = g_l2[1];
    assign p_l3[1] = p_l2[1];
    assign g_l3[2] = g_l2[2];
    assign p_l3[2] = p_l2[2];
    assign g_l3[3] = g_l2[3];
    assign p_l3[3] = p_l2[3];
    
    generate
        for (i = 4; i < 8; i = i + 1) begin : level3
            assign g_l3[i] = g_l2[i] | (p_l2[i] & g_l2[i-4]);
            assign p_l3[i] = p_l2[i] & p_l2[i-4];
        end
    endgenerate
    
    // 计算进位
    assign carry[0] = 1'b0;  // 无进位输入
    assign carry[1] = g_l3[0];
    assign carry[2] = g_l3[1];
    assign carry[3] = g_l3[2];
    assign carry[4] = g_l3[3];
    assign carry[5] = g_l3[4];
    assign carry[6] = g_l3[5];
    assign carry[7] = g_l3[6];
    
    // 计算和
    assign sum = p_init ^ {carry[7:1], 1'b0};
endmodule
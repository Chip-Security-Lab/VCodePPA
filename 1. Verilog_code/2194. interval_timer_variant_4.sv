//SystemVerilog
module interval_timer (
    input wire clk,
    input wire rst,
    input wire program_en,
    input wire [7:0] interval_data,
    input wire [3:0] interval_sel,
    output reg event_trigger
);
    reg [7:0] intervals [0:15];
    reg [7:0] current_count;
    reg [3:0] active_interval;
    reg count_reset;
    
    // 输入寄存器 - 为输入添加寄存器以减少输入延迟
    reg program_en_reg;
    reg [7:0] interval_data_reg;
    reg [3:0] interval_sel_reg;
    
    // 中间信号寄存器
    reg interval_complete_reg;
    reg [7:0] next_count_reg;
    
    wire [7:0] next_count;
    wire interval_complete;
    
    // 注册输入信号
    always @(posedge clk) begin
        if (rst) begin
            program_en_reg <= 1'b0;
            interval_data_reg <= 8'd0;
            interval_sel_reg <= 4'd0;
        end else begin
            program_en_reg <= program_en;
            interval_data_reg <= interval_data;
            interval_sel_reg <= interval_sel;
        end
    end
    
    // Brent-Kung加法器实例化
    brent_kung_adder adder (
        .a(current_count),
        .b(8'd1),
        .sum(next_count)
    );
    
    // 比较逻辑
    assign interval_complete = (current_count >= intervals[active_interval]);
    
    // 注册中间信号
    always @(posedge clk) begin
        if (rst) begin
            interval_complete_reg <= 1'b0;
            next_count_reg <= 8'd0;
        end else begin
            interval_complete_reg <= interval_complete;
            next_count_reg <= next_count;
        end
    end

    // 计数器更新逻辑 - 使用注册后的信号
    always @(posedge clk) begin
        if (rst) begin
            current_count <= 8'd0;
        end else if (count_reset) begin
            current_count <= 8'd0;
        end else if (!program_en_reg) begin
            current_count <= next_count_reg; // 使用注册后的next_count
        end
    end
    
    // 区间编程逻辑 - 使用注册后的信号
    always @(posedge clk) begin
        if (rst) begin
            // 在复位时不需要重置intervals数组，因为它会占用过多资源
        end else if (program_en_reg) begin
            intervals[interval_sel_reg] <= interval_data_reg;
        end
    end
    
    // 事件触发和活动区间控制逻辑 - 使用注册后的信号
    always @(posedge clk) begin
        if (rst) begin
            event_trigger <= 1'b0;
            active_interval <= 4'd0;
            count_reset <= 1'b0;
        end else if (!program_en_reg && interval_complete_reg) begin
            event_trigger <= 1'b1;
            active_interval <= active_interval + 1'b1;
            count_reset <= 1'b1;
        end else begin
            event_trigger <= 1'b0;
            count_reset <= 1'b0;
        end
    end
endmodule

// Brent-Kung加法器模块实现（8位）- 添加输入和输出寄存器
module brent_kung_adder (
    input [7:0] a,
    input [7:0] b,
    output reg [7:0] sum
);
    wire [7:0] p, g; // 传播和生成信号
    wire [7:0] pp, gg; // 第二级传播和生成信号
    wire [7:0] c; // 进位信号
    wire [7:0] sum_wire; // 临时求和结果
    
    reg [7:0] a_reg, b_reg;
    wire [7:0] p_wire, g_wire;
    
    // 输入寄存器
    always @(a, b) begin
        a_reg = a;
        b_reg = b;
    end
    
    // 第一级：生成初始的传播和生成信号
    generate_pg pg_gen (
        .a(a_reg),
        .b(b_reg),
        .p(p),
        .g(g)
    );
    
    // 第二级：计算组传播和生成信号
    compute_group_pg group_pg (
        .p(p),
        .g(g),
        .pp(pp),
        .gg(gg)
    );
    
    // 第三级：计算进位信号
    compute_carries carry_gen (
        .p(p),
        .g(g),
        .pp(pp),
        .gg(gg),
        .cin(1'b0),
        .c(c)
    );
    
    // 第四级：计算最终和
    compute_sum sum_gen (
        .a(a_reg),
        .b(b_reg),
        .c(c),
        .sum(sum_wire)
    );
    
    // 输出寄存器
    always @(sum_wire) begin
        sum = sum_wire;
    end
endmodule

// 生成初始传播和生成信号
module generate_pg (
    input [7:0] a,
    input [7:0] b,
    output [7:0] p,
    output [7:0] g
);
    assign p = a ^ b; // 传播 = a XOR b
    assign g = a & b; // 生成 = a AND b
endmodule

// 计算组传播和生成信号 - 添加寄存器减少关键路径
module compute_group_pg (
    input [7:0] p,
    input [7:0] g,
    output [7:0] pp,
    output [7:0] gg
);
    // 第一级组计算的寄存器
    reg [3:0] pp_level1;
    reg [3:0] gg_level1;
    
    // 第一级组计算 (2位组)
    always @(*) begin
        pp_level1[0] = p[1] & p[0];
        gg_level1[0] = g[1] | (p[1] & g[0]);
        
        pp_level1[1] = p[3] & p[2];
        gg_level1[1] = g[3] | (p[3] & g[2]);
        
        pp_level1[2] = p[5] & p[4];
        gg_level1[2] = g[5] | (p[5] & g[4]);
        
        pp_level1[3] = p[7] & p[6];
        gg_level1[3] = g[7] | (p[7] & g[6]);
    end
    
    // 第二级组计算 (4位组)
    assign pp[3] = pp_level1[1] & pp_level1[0];
    assign gg[3] = gg_level1[1] | (pp_level1[1] & gg_level1[0]);
    
    assign pp[7] = pp_level1[3] & pp_level1[2];
    assign gg[7] = gg_level1[3] | (pp_level1[3] & gg_level1[2]);
    
    // 传递第一级结果到输出
    assign pp[1] = pp_level1[0];
    assign gg[1] = gg_level1[0];
    assign pp[5] = pp_level1[2];
    assign gg[5] = gg_level1[2];
    
    // 其他位未使用，设为0
    assign pp[0] = 1'b0;
    assign gg[0] = 1'b0;
    assign pp[2] = 1'b0;
    assign gg[2] = 1'b0;
    assign pp[4] = 1'b0;
    assign gg[4] = 1'b0;
    assign pp[6] = 1'b0;
    assign gg[6] = 1'b0;
endmodule

// 计算进位 - 分解流水线减少关键路径
module compute_carries (
    input [7:0] p,
    input [7:0] g,
    input [7:0] pp,
    input [7:0] gg,
    input cin,
    output [7:0] c
);
    // 低位进位计算
    assign c[0] = cin;
    assign c[1] = g[0] | (p[0] & cin);
    assign c[2] = g[1] | (p[1] & c[1]);
    assign c[3] = g[2] | (p[2] & c[2]);
    
    // 高位进位计算（使用组生成和传播信号）
    assign c[4] = gg[3] | (pp[3] & cin);
    assign c[5] = g[4] | (p[4] & c[4]);
    assign c[6] = g[5] | (p[5] & c[5]);
    assign c[7] = g[6] | (p[6] & c[6]);
endmodule

// 计算最终和
module compute_sum (
    input [7:0] a,
    input [7:0] b,
    input [7:0] c,
    output [7:0] sum
);
    assign sum = a ^ b ^ {c[6:0], 1'b0};
endmodule
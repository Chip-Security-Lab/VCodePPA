//SystemVerilog
// SystemVerilog (IEEE 1364-2005)
// 顶层模块
module simon_light #(
    parameter ROUNDS = 44
)(
    input clk, load_key,
    input [63:0] block_in,
    input [127:0] key_in,
    output reg [63:0] block_out
);
    // 内部连接信号
    wire [31:0] new_left;
    reg [31:0] left, right;
    
    // 高扇出信号缓冲寄存器
    reg [4:0] rounds_buf1, rounds_buf2;
    reg [127:0] key_in_buf1, key_in_buf2;
    
    // 左右数据缓冲寄存器
    reg [31:0] left_buf1, left_buf2, right_buf1, right_buf2;
    
    // 轮密钥缓冲
    wire [63:0] current_round_key;
    reg [63:0] current_round_key_buf1, current_round_key_buf2;
    
    // 参数缓冲 - 第一级缓冲
    always @(posedge clk) begin
        rounds_buf1 <= ROUNDS[4:0];
        key_in_buf1 <= key_in;
        left_buf1 <= left;
        right_buf1 <= right;
        current_round_key_buf1 <= current_round_key;
    end
    
    // 参数缓冲 - 第二级缓冲
    always @(posedge clk) begin
        rounds_buf2 <= rounds_buf1;
        key_in_buf2 <= key_in_buf1;
        left_buf2 <= left_buf1;
        right_buf2 <= right_buf1;
        current_round_key_buf2 <= current_round_key_buf1;
    end
    
    // 密钥扩展模块例化
    key_expansion #(
        .ROUNDS(ROUNDS)
    ) key_exp_inst (
        .clk(clk),
        .load_key(load_key),
        .key_in(key_in_buf1),  // 使用缓冲的输入
        .current_round_key(current_round_key)
    );
    
    // 加密运算模块例化
    encryption_round enc_round_inst (
        .left(left_buf2),       // 使用缓冲的左半部分
        .right(right_buf2),     // 使用缓冲的右半部分
        .round_key(current_round_key_buf2[31:0]),  // 使用缓冲的轮密钥
        .new_left(new_left)
    );
    
    // 数据处理和输出控制
    always @(posedge clk) begin
        if (!load_key) begin
            left = block_in[63:32];
            right = block_in[31:0];
            
            // 更新输出
            block_out <= {right, new_left};
        end
    end
endmodule

// 密钥扩展模块
module key_expansion #(
    parameter ROUNDS = 44
)(
    input clk,
    input load_key,
    input [127:0] key_in,
    output [63:0] current_round_key
);
    reg [63:0] key_schedule [0:ROUNDS-1];
    integer r;
    
    // 将ROUNDS参数缓存到局部变量,减少扇出
    reg [5:0] rounds_local;
    
    // 密钥扩展中间寄存器,减少扇出
    reg [63:0] prev_key;
    reg [2:0] rotated_bits;
    
    always @(posedge clk) begin
        rounds_local <= ROUNDS;
    end
    
    // 密钥扩展逻辑
    always @(posedge clk) begin
        if (load_key) begin
            key_schedule[0] <= key_in[63:0];
            prev_key <= key_in[63:0];
            
            for(r=1; r<ROUNDS; r=r+1) begin
                if (r == 1) begin
                    // 第一轮使用直接输入
                    rotated_bits <= prev_key[63:61] ^ 3'h5;
                    key_schedule[r][63:3] <= prev_key[60:0];
                    key_schedule[r][2:0] <= prev_key[63:61] ^ 3'h5;
                end else begin
                    // 后续轮使用上一轮计算结果
                    key_schedule[r][63:3] <= key_schedule[r-1][60:0];
                    key_schedule[r][2:0] <= key_schedule[r-1][63:61] ^ 3'h5;
                end
                
                // 更新前一个密钥值用于下一轮
                if (r < ROUNDS-1) begin
                    prev_key <= key_schedule[r];
                end
            end
        end
    end
    
    // 输出当前轮密钥
    assign current_round_key = key_schedule[0];
endmodule

// 加密轮函数模块
module encryption_round (
    input [31:0] left,
    input [31:0] right,
    input [31:0] round_key,
    output [31:0] new_left
);
    wire [31:0] rotated_left;
    
    // 计算左半部分的旋转
    assign rotated_left = (left << 1) | (left >> 31);
    
    // 实例化并行前缀加法器
    prefix_adder adder_inst (
        .a(right),
        .b(rotated_left),
        .cin(1'b0),
        .result(new_left),
        .key(round_key)
    );
endmodule

// 前缀加法器顶层模块
module prefix_adder (
    input [31:0] a,
    input [31:0] b,
    input cin,
    output [31:0] result,
    input [31:0] key
);
    wire [31:0] g, p;          // 基本生成和传播信号
    wire [31:0] carry;         // 进位信号
    wire [31:0] prefix_carry;  // 前缀计算得到的进位
    
    // 寄存器缓冲来减少a、b、key的扇出
    reg [31:0] a_buf, b_buf, key_buf;
    reg cin_buf;
    
    // 输入信号缓冲
    always @(*) begin
        a_buf = a;
        b_buf = b;
        key_buf = key;
        cin_buf = cin;
    end
    
    // 生成基本的生成和传播信号
    prefix_generator pg_inst (
        .a(a_buf),
        .b(b_buf),
        .g(g),
        .p(p)
    );
    
    // 前缀网络计算
    prefix_network pn_inst (
        .g(g),
        .p(p),
        .cin(cin_buf),
        .carry(prefix_carry)
    );
    
    // 计算最终结果
    result_calculator rc_inst (
        .p(p),
        .carry(prefix_carry),
        .cin(cin_buf),
        .key(key_buf),
        .result(result)
    );
endmodule

// 生成基本生成和传播信号模块
module prefix_generator (
    input [31:0] a,
    input [31:0] b,
    output [31:0] g,
    output [31:0] p
);
    // 计算基本生成和传播信号
    assign g = a & b;      // 生成信号
    assign p = a ^ b;      // 传播信号
endmodule

// 前缀网络计算模块 (Kogge-Stone算法)
module prefix_network (
    input [31:0] g,
    input [31:0] p,
    input cin,
    output [31:0] carry
);
    // 对高扇出信号进行缓冲
    reg [31:0] g_buf, p_buf;
    reg cin_buf;
    
    always @(*) begin
        g_buf = g;
        p_buf = p;
        cin_buf = cin;
    end
    
    // 前缀计算中间信号
    wire [31:0] g_z, p_z;  // 第0级前缀
    wire [31:0] g_a, p_a;  // 第1级前缀
    wire [31:0] g_b, p_b;  // 第2级前缀
    wire [31:0] g_c, p_c;  // 第3级前缀
    wire [31:0] g_d, p_d;  // 第4级前缀
    
    // 为扇出较大的前缀信号添加缓冲
    reg [31:0] g_z_buf, p_z_buf;
    reg [31:0] g_a_buf, p_a_buf;
    reg [31:0] g_b_buf, p_b_buf;
    reg [31:0] g_c_buf, p_c_buf;
    
    // 级别0（1位步长）
    assign g_z[0] = g_buf[0] | (p_buf[0] & cin_buf);
    assign p_z[0] = p_buf[0];
    
    genvar i;
    generate
        for (i = 1; i < 32; i = i + 1) begin : level_0
            assign g_z[i] = g_buf[i] | (p_buf[i] & g_buf[i-1]);
            assign p_z[i] = p_buf[i] & p_buf[i-1];
        end
    endgenerate
    
    // 缓冲第0级输出
    always @(*) begin
        g_z_buf = g_z;
        p_z_buf = p_z;
    end
    
    // 级别1（2位步长）
    assign g_a[0] = g_z_buf[0];
    assign p_a[0] = p_z_buf[0];
    assign g_a[1] = g_z_buf[1];
    assign p_a[1] = p_z_buf[1];
    
    generate
        for (i = 2; i < 32; i = i + 1) begin : level_1
            assign g_a[i] = g_z_buf[i] | (p_z_buf[i] & g_z_buf[i-2]);
            assign p_a[i] = p_z_buf[i] & p_z_buf[i-2];
        end
    endgenerate
    
    // 缓冲第1级输出
    always @(*) begin
        g_a_buf = g_a;
        p_a_buf = p_a;
    end
    
    // 级别2（4位步长）
    generate
        for (i = 0; i < 4; i = i + 1) begin : level_2_first
            assign g_b[i] = g_a_buf[i];
            assign p_b[i] = p_a_buf[i];
        end
        
        for (i = 4; i < 32; i = i + 1) begin : level_2_rest
            assign g_b[i] = g_a_buf[i] | (p_a_buf[i] & g_a_buf[i-4]);
            assign p_b[i] = p_a_buf[i] & p_a_buf[i-4];
        end
    endgenerate
    
    // 缓冲第2级输出
    always @(*) begin
        g_b_buf = g_b;
        p_b_buf = p_b;
    end
    
    // 级别3（8位步长）
    generate
        for (i = 0; i < 8; i = i + 1) begin : level_3_first
            assign g_c[i] = g_b_buf[i];
            assign p_c[i] = p_b_buf[i];
        end
        
        for (i = 8; i < 32; i = i + 1) begin : level_3_rest
            assign g_c[i] = g_b_buf[i] | (p_b_buf[i] & g_b_buf[i-8]);
            assign p_c[i] = p_b_buf[i] & p_b_buf[i-8];
        end
    endgenerate
    
    // 缓冲第3级输出
    always @(*) begin
        g_c_buf = g_c;
        p_c_buf = p_c;
    end
    
    // 级别4（16位步长）
    generate
        for (i = 0; i < 16; i = i + 1) begin : level_4_first
            assign g_d[i] = g_c_buf[i];
            assign p_d[i] = p_c_buf[i];
        end
        
        for (i = 16; i < 32; i = i + 1) begin : level_4_rest
            assign g_d[i] = g_c_buf[i] | (p_c_buf[i] & g_c_buf[i-16]);
            assign p_d[i] = p_c_buf[i] & p_c_buf[i-16];
        end
    endgenerate
    
    // 计算进位
    assign carry[0] = cin_buf;
    generate
        for (i = 1; i < 32; i = i + 1) begin : compute_carry
            assign carry[i] = g_d[i-1];
        end
    endgenerate
endmodule

// 结果计算模块
module result_calculator (
    input [31:0] p,
    input [31:0] carry,
    input cin,
    input [31:0] key,
    output [31:0] result
);
    // 对高扇出信号添加缓冲
    reg [31:0] p_buf, carry_buf, key_buf;
    
    always @(*) begin
        p_buf = p;
        carry_buf = carry;
        key_buf = key;
    end
    
    // 计算最终的加法结果与密钥异或
    assign result = (p_buf ^ carry_buf) ^ key_buf;
endmodule
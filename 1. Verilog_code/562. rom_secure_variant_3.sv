//SystemVerilog
// 顶层模块
module rom_secure #(parameter KEY=32'hA5A5A5A5)(
    input [31:0] key,
    input [4:0] addr,
    output [127:0] data
);
    // 内部连线
    wire key_valid;
    wire [127:0] raw_data;
    
    // 子模块实例化
    key_validator #(
        .VALID_KEY(KEY)
    ) key_check (
        .key(key),
        .key_valid(key_valid)
    );
    
    encrypted_memory mem (
        .addr(addr),
        .raw_data(raw_data)
    );
    
    secure_output_gate output_control (
        .key_valid(key_valid),
        .raw_data(raw_data),
        .data(data)
    );
endmodule

// 密钥验证模块
module key_validator #(parameter VALID_KEY=32'hA5A5A5A5)(
    input [31:0] key,
    output key_valid
);
    // 比较输入密钥与预设密钥
    assign key_valid = (key == VALID_KEY);
endmodule

// 加密存储器模块
module encrypted_memory (
    input [4:0] addr,
    output [127:0] raw_data
);
    reg [127:0] encrypted [0:31];
    
    // 初始化存储器内容
    integer i;
    initial begin
        for (i = 0; i < 32; i = i + 1)
            encrypted[i] = {32'hDEADBEEF, 32'hCAFEBABE, 32'h12345678, 32'h87654321} ^ {i, i, i, i};
    end
    
    // 地址解码和数据读取
    assign raw_data = encrypted[addr];
endmodule

// 安全输出控制模块 - 使用Han-Carlson加法器实现
module secure_output_gate (
    input key_valid,
    input [127:0] raw_data,
    output [127:0] data
);
    // 将使用Han-Carlson加法器处理数据
    wire [127:0] processed_data;
    
    // 当key_valid为真时，使用Han-Carlson加法器处理数据，否则输出0
    assign data = key_valid ? processed_data : 128'h0;
    
    // Han-Carlson 加法器实现
    han_carlson_adder #(
        .WIDTH(128)
    ) hc_adder (
        .a(raw_data),
        .b(128'h0),  // 加0保持原值，但通过加法器处理
        .sum(processed_data)
    );
endmodule

// Han-Carlson加法器模块
module han_carlson_adder #(
    parameter WIDTH = 128
)(
    input [WIDTH-1:0] a,
    input [WIDTH-1:0] b,
    output [WIDTH-1:0] sum
);
    // 进位生成和传播信号
    wire [WIDTH-1:0] g, p;
    wire [WIDTH-1:0] c;
    
    // 阶段1: 预计算
    genvar i;
    generate
        for (i = 0; i < WIDTH; i = i + 1) begin: gen_gp
            assign g[i] = a[i] & b[i];
            assign p[i] = a[i] | b[i];
        end
    endgenerate
    
    // 阶段2: 并行前缀计算 (Han-Carlson特点：只处理偶数位)
    wire [WIDTH-1:0] g_temp [0:$clog2(WIDTH)];
    wire [WIDTH-1:0] p_temp [0:$clog2(WIDTH)];
    
    // 初始化
    generate
        for (i = 0; i < WIDTH; i = i + 1) begin: init_temp
            assign g_temp[0][i] = g[i];
            assign p_temp[0][i] = p[i];
        end
    endgenerate
    
    // Han-Carlson前缀树计算
    generate
        for (i = 1; i <= $clog2(WIDTH); i = i + 1) begin: hc_stages
            genvar j;
            for (j = 0; j < WIDTH; j = j + 1) begin: hc_bits
                if (j >= (1 << (i-1))) begin
                    if (j % 2 == 0) begin // 只处理偶数位
                        assign g_temp[i][j] = g_temp[i-1][j] | (p_temp[i-1][j] & g_temp[i-1][j-(1<<(i-1))]);
                        assign p_temp[i][j] = p_temp[i-1][j] & p_temp[i-1][j-(1<<(i-1))];
                    end else begin // 奇数位直接传递
                        assign g_temp[i][j] = g_temp[i-1][j];
                        assign p_temp[i][j] = p_temp[i-1][j];
                    end
                end else begin
                    assign g_temp[i][j] = g_temp[i-1][j];
                    assign p_temp[i][j] = p_temp[i-1][j];
                end
            end
        end
    endgenerate
    
    // 阶段3: 奇数位计算
    wire [WIDTH-1:0] g_final, p_final;
    
    generate
        for (i = 0; i < WIDTH; i = i + 1) begin: final_stage
            if (i % 2 == 0) begin // 偶数位
                assign g_final[i] = g_temp[$clog2(WIDTH)][i];
                assign p_final[i] = p_temp[$clog2(WIDTH)][i];
            end else begin // 奇数位需要从前一个偶数位计算
                assign g_final[i] = g_temp[$clog2(WIDTH)][i] | (p_temp[$clog2(WIDTH)][i] & g_final[i-1]);
                assign p_final[i] = p_temp[$clog2(WIDTH)][i] & p_final[i-1];
            end
        end
    endgenerate
    
    // 进位计算
    assign c[0] = 1'b0; // 无初始进位
    generate
        for (i = 1; i < WIDTH; i = i + 1) begin: carry_gen
            assign c[i] = g_final[i-1];
        end
    endgenerate
    
    // 计算最终和
    generate
        for (i = 0; i < WIDTH; i = i + 1) begin: sum_gen
            assign sum[i] = a[i] ^ b[i] ^ c[i];
        end
    endgenerate
endmodule
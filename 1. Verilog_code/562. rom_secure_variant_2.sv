//SystemVerilog
// 顶层模块
module rom_secure #(parameter KEY=32'hA5A5A5A5)(
    input [31:0] key,
    input [4:0] addr,
    output [127:0] data
);
    wire key_valid;
    wire [127:0] encrypted_data;
    
    // 子模块实例化
    key_validator #(
        .KEY(KEY)
    ) key_check (
        .key(key),
        .key_valid(key_valid)
    );
    
    encrypted_memory mem_block (
        .addr(addr),
        .encrypted_data(encrypted_data)
    );
    
    data_output output_ctrl (
        .key_valid(key_valid),
        .encrypted_data(encrypted_data),
        .data(data)
    );
endmodule

// 密钥验证子模块
module key_validator #(parameter KEY=32'hA5A5A5A5)(
    input [31:0] key,
    output key_valid
);
    assign key_valid = (key == KEY);
endmodule

// 加密存储器子模块
module encrypted_memory (
    input [4:0] addr,
    output [127:0] encrypted_data
);
    reg [127:0] encrypted [0:31];
    wire [127:0] base_data;
    wire [127:0] xor_data;
    
    // Initialize memory with encrypted values
    integer i;
    initial begin
        for (i = 0; i < 32; i = i + 1)
            encrypted[i] = {32'hDEADBEEF, 32'hCAFEBABE, 32'h12345678, 32'h87654321};
    end
    
    assign base_data = encrypted[addr];
    assign xor_data = {addr, addr, addr, addr};
    
    // 使用Kogge-Stone加法器进行运算
    kogge_stone_adder #(
        .WIDTH(128)
    ) adder_inst (
        .a(base_data),
        .b(xor_data),
        .sum(encrypted_data)
    );
endmodule

// 数据输出控制子模块
module data_output (
    input key_valid,
    input [127:0] encrypted_data,
    output reg [127:0] data
);
    always @(*) begin
        data = key_valid ? encrypted_data : 128'h0;
    end
endmodule

// Kogge-Stone并行前缀加法器
module kogge_stone_adder #(
    parameter WIDTH = 128
)(
    input [WIDTH-1:0] a,
    input [WIDTH-1:0] b,
    output [WIDTH-1:0] sum
);
    // 定义生成(G)和传播(P)信号
    wire [WIDTH-1:0] g_init, p_init;
    wire [WIDTH-1:0] g_level[0:$clog2(WIDTH)];
    wire [WIDTH-1:0] p_level[0:$clog2(WIDTH)];
    
    // 初始化生成和传播信号
    assign g_init = a & b;      // 生成信号
    assign p_init = a ^ b;      // 传播信号
    
    // 第0级: 复制初始信号
    genvar i, j, k;
    generate
        for (i = 0; i < WIDTH; i = i + 1) begin: gen_level0
            assign g_level[0][i] = g_init[i];
            assign p_level[0][i] = p_init[i];
        end
        
        // 实现Kogge-Stone的并行前缀结构
        for (i = 1; i <= $clog2(WIDTH); i = i + 1) begin: gen_levels
            for (j = 0; j < WIDTH; j = j + 1) begin: gen_bit
                if (j >= (1 << (i-1))) begin: gen_update
                    assign g_level[i][j] = g_level[i-1][j] | (p_level[i-1][j] & g_level[i-1][j-(1<<(i-1))]);
                    assign p_level[i][j] = p_level[i-1][j] & p_level[i-1][j-(1<<(i-1))];
                end else begin: gen_passthrough
                    assign g_level[i][j] = g_level[i-1][j];
                    assign p_level[i][j] = p_level[i-1][j];
                end
            end
        end
        
        // 计算最终的和
        assign sum[0] = p_init[0];
        for (k = 1; k < WIDTH; k = k + 1) begin: gen_sum
            assign sum[k] = p_init[k] ^ g_level[$clog2(WIDTH)][k-1];
        end
    endgenerate
endmodule
//SystemVerilog
//IEEE 1364-2005 Verilog
// 顶层模块 - 双端口解码器
module decoder_dual_port (
    input  wire [3:0]  rd_addr,  // 读地址输入
    input  wire [3:0]  wr_addr,  // 写地址输入 
    output wire [15:0] rd_sel,   // 读选择输出
    output wire [15:0] wr_sel    // 写选择输出
);
    // 模块参数
    localparam DECODER_ENABLE = 1'b1;
    
    // 主数据通路 - 读地址解码
    decoder_4to16 #(
        .ENABLE(DECODER_ENABLE)
    ) u_rd_decoder (
        .addr_i(rd_addr),
        .sel_o(rd_sel)
    );
    
    // 主数据通路 - 写地址解码
    decoder_4to16 #(
        .ENABLE(DECODER_ENABLE)
    ) u_wr_decoder (
        .addr_i(wr_addr),
        .sel_o(wr_sel)
    );
endmodule

// 优化的4位到16位地址解码器子模块
module decoder_4to16 (
    input  wire [3:0]  addr_i,  // 地址输入
    output wire [15:0] sel_o    // 选择输出
);
    // 模块参数
    parameter ENABLE = 1'b1;
    
    // 内部信号 - 分段解码以减少路径延迟
    wire [1:0] addr_high;  // 高位地址
    wire [1:0] addr_low;   // 低位地址
    reg  [3:0] row_decode; // 行解码结果
    reg  [3:0] col_decode; // 列解码结果
    
    // 地址分段
    assign addr_high = addr_i[3:2];
    assign addr_low  = addr_i[1:0];
    
    // 第一级解码 - 行解码 (2-to-4)
    always @(*) begin
        row_decode = 4'b0000;
        if (ENABLE) begin
            case (addr_high)
                2'b00: row_decode = 4'b0001;
                2'b01: row_decode = 4'b0010;
                2'b10: row_decode = 4'b0100;
                2'b11: row_decode = 4'b1000;
            endcase
        end
    end
    
    // 第一级解码 - 列解码 (2-to-4)
    always @(*) begin
        col_decode = 4'b0000;
        if (ENABLE) begin
            case (addr_low)
                2'b00: col_decode = 4'b0001;
                2'b01: col_decode = 4'b0010;
                2'b10: col_decode = 4'b0100;
                2'b11: col_decode = 4'b1000;
            endcase
        end
    end
    
    // 第二级解码 - 组合行列解码生成最终输出
    // 使用结构化的行列矩阵降低逻辑深度
    genvar i, j;
    generate
        for (i = 0; i < 4; i = i + 1) begin: row_gen
            for (j = 0; j < 4; j = j + 1) begin: col_gen
                assign sel_o[i*4 + j] = row_decode[i] & col_decode[j];
            end
        end
    endgenerate
    
endmodule

// Han-Carlson 16位加法器实现
module han_carlson_adder_16bit (
    input  wire [15:0] a,      // 加数A
    input  wire [15:0] b,      // 加数B
    input  wire        cin,    // 进位输入
    output wire [15:0] sum,    // 和
    output wire        cout    // 进位输出
);
    // 预处理 - 生成传播与生成信号
    wire [15:0] p, g;
    
    // 第一阶段: 生成传播与生成信号
    assign p = a ^ b;              // 传播信号
    assign g = a & b;              // 生成信号
    
    // 第二阶段: Han-Carlson前缀树处理
    wire [15:0] pp, gg;            // 第一级前缀输出
    wire [15:0] ppp, ggg;          // 第二级前缀输出
    wire [15:0] pppp, gggg;        // 第三级前缀输出
    wire [15:0] carry;             // 内部进位信号
    
    // 初始进位处理
    wire cin_effect = cin;
    
    // 阶段 1: 偶数位置前缀计算
    genvar i;
    generate
        // 初始位特殊处理
        assign pp[0] = p[0];
        assign gg[0] = g[0];
        
        // 偶数位前缀计算
        for (i = 2; i < 16; i = i + 2) begin: stage1_even
            assign pp[i] = p[i] & p[i-1];
            assign gg[i] = g[i] | (p[i] & g[i-1]);
        end
        
        // 奇数位直接传递(除了第一位)
        for (i = 1; i < 16; i = i + 2) begin: stage1_odd
            assign pp[i] = p[i];
            assign gg[i] = g[i];
        end
    endgenerate
    
    // 阶段 2: 2跨步前缀计算
    generate
        // 低位(0,1)直接传递
        assign ppp[0] = pp[0];
        assign ggg[0] = gg[0];
        assign ppp[1] = pp[1];
        assign ggg[1] = gg[1];
        
        // 计算偶数位
        for (i = 2; i < 16; i = i + 2) begin: stage2_even
            assign ppp[i] = pp[i] & pp[i-2];
            assign ggg[i] = gg[i] | (pp[i] & gg[i-2]);
        end
        
        // 奇数位(除了第一位)
        for (i = 3; i < 16; i = i + 2) begin: stage2_odd
            assign ppp[i] = pp[i] & pp[i-2];
            assign ggg[i] = gg[i] | (pp[i] & gg[i-2]);
        end
    endgenerate
    
    // 阶段 3: 4跨步前缀计算
    generate
        // 低位(0-3)直接传递
        for (i = 0; i < 4; i = i + 1) begin: stage3_low
            assign pppp[i] = ppp[i];
            assign gggg[i] = ggg[i];
        end
        
        // 计算其余位置
        for (i = 4; i < 16; i = i + 1) begin: stage3_rest
            assign pppp[i] = ppp[i] & ppp[i-4];
            assign gggg[i] = ggg[i] | (ppp[i] & ggg[i-4]);
        end
    endgenerate
    
    // 阶段 4: 8跨步前缀计算并生成进位
    generate
        // 处理初始位进位
        assign carry[0] = cin_effect;
        
        // 为第1位生成进位
        assign carry[1] = gggg[0] | (pppp[0] & cin_effect);
        
        // 生成偶数位进位
        for (i = 2; i < 16; i = i + 2) begin: carry_even
            assign carry[i] = gggg[i-1] | (pppp[i-1] & cin_effect);
        end
        
        // 生成奇数位进位(除了第1位)
        for (i = 3; i < 16; i = i + 2) begin: carry_odd
            assign carry[i] = gggg[i-1] | (pppp[i-1] & cin_effect);
        end
    endgenerate
    
    // 最终和计算
    generate
        for (i = 0; i < 16; i = i + 1) begin: sum_calc
            assign sum[i] = p[i] ^ carry[i];
        end
    endgenerate
    
    // 输出进位
    assign cout = gggg[15] | (pppp[15] & cin_effect);
    
endmodule
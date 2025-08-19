//SystemVerilog
module gcm_auth #(parameter WIDTH = 32) (
    input wire clk, reset_l,
    input wire data_valid, last_block,
    input wire [WIDTH-1:0] data_in, h_key,
    output reg [WIDTH-1:0] auth_tag,
    output reg tag_valid
);
    // 缓冲WIDTH参数到多个模块以减少扇出
    localparam W = WIDTH;
    
    reg [W-1:0] accumulated;
    
    // 流水线寄存器
    reg [W-1:0] gf_mult_stage1;
    reg [W-1:0] combined_data;
    reg mult_in_progress;
    reg last_block_r;
    
    // 为高扇出信号添加缓冲寄存器
    reg [W-1:0] data_in_buf1, data_in_buf2;
    reg [W-1:0] accumulated_buf1, accumulated_buf2;
    
    // 并行前缀减法器信号
    wire [W-1:0] xor_result;
    wire [W:0] borrow;
    wire [W-1:0] sub_result;
    reg [W:0] borrow_buf[1:0]; // 添加缓冲缓解borrow的高扇出
    
    // 缓冲高扇出信号
    always @(posedge clk) begin
        if (!reset_l) begin
            data_in_buf1 <= 0;
            data_in_buf2 <= 0;
            accumulated_buf1 <= 0;
            accumulated_buf2 <= 0;
        end else begin
            data_in_buf1 <= data_in;
            data_in_buf2 <= data_in_buf1;
            accumulated_buf1 <= accumulated;
            accumulated_buf2 <= accumulated_buf1;
        end
    end
    
    // 异或运算 - 为高扇出信号添加缓冲
    assign xor_result = accumulated_buf1 ^ data_in_buf1;
    
    // 借位信号缓冲
    always @(*) begin
        borrow_buf[0][0] = 1'b0;
        borrow_buf[1][0] = 1'b0;
    end
    
    // 并行前缀减法器实现 - 分组以平衡负载
    // 生成初始借位信号
    assign borrow[0] = 1'b0;  // 初始无借位
    
    // 借位信号生成网络 - 分成两组以减少扇出
    genvar i;
    generate
        for (i = 0; i < W/2; i = i + 1) begin : gen_borrow_low
            assign borrow[i+1] = (accumulated_buf1[i] & data_in_buf1[i]) | 
                               (~accumulated_buf1[i] & (data_in_buf1[i] | borrow[i]));
            // 缓冲中间借位信号
            always @(*) begin
                borrow_buf[0][i+1] = borrow[i+1];
            end
        end
        
        for (i = W/2; i < W; i = i + 1) begin : gen_borrow_high
            assign borrow[i+1] = (accumulated_buf2[i] & data_in_buf2[i]) | 
                               (~accumulated_buf2[i] & (data_in_buf2[i] | borrow[i]));
            // 缓冲中间借位信号
            always @(*) begin
                borrow_buf[1][i+1] = borrow[i+1];
            end
        end
    endgenerate
    
    // 计算减法结果 - 分组以平衡负载
    generate
        for (i = 0; i < W/2; i = i + 1) begin : gen_sub_low
            assign sub_result[i] = accumulated_buf1[i] ^ data_in_buf1[i] ^ borrow_buf[0][i];
        end
        
        for (i = W/2; i < W; i = i + 1) begin : gen_sub_high
            assign sub_result[i] = accumulated_buf2[i] ^ data_in_buf2[i] ^ borrow_buf[1][i];
        end
    endgenerate
    
    // 为GF乘法函数的结果添加缓冲寄存器
    reg [W-1:0] xor_result_buf;
    reg [W-1:0] h_key_buf;
    
    // GF(2^128) 乘法函数 - 第一阶段：计算初始乘法结果
    function [W-1:0] gf_mult_p1(input [W-1:0] a, b);
        reg [W-1:0] res;
        integer i;
        begin
            res = 0;
            for (i = 0; i < W; i = i + 1) begin
                if (a[i]) res = res ^ (b << i);
            end
            gf_mult_p1 = res;
        end
    endfunction
    
    // GF(2^128) 乘法函数 - 第二阶段：执行归约
    function [W-1:0] gf_mult_p2(input [W-1:0] res);
        reg [W-1:0] result;
        integer j;
        begin
            result = res;
            for (j = W*2-1; j >= W; j = j - 1) begin
                if (result[j]) result = result ^ (32'h87000000 << (j - W));
            end
            gf_mult_p2 = result;
        end
    endfunction
    
    // 第一阶段：数据组合和初始乘法 - 添加中间缓冲
    always @(posedge clk or negedge reset_l) begin
        if (!reset_l) begin
            xor_result_buf <= 0;
            h_key_buf <= 0;
        end else begin
            xor_result_buf <= xor_result;
            h_key_buf <= h_key;
        end
    end
    
    // 第一阶段处理逻辑
    always @(posedge clk or negedge reset_l) begin
        if (!reset_l) begin
            combined_data <= 0;
            gf_mult_stage1 <= 0;
            mult_in_progress <= 0;
            last_block_r <= 0;
        end else if (data_valid) begin
            combined_data <= xor_result_buf;  // 使用缓冲的XOR结果
            gf_mult_stage1 <= gf_mult_p1(xor_result_buf, h_key_buf);
            mult_in_progress <= 1;
            last_block_r <= last_block;
        end else begin
            mult_in_progress <= 0;
        end
    end
    
    // 缓冲乘法结果
    reg [W-1:0] gf_mult_result;
    
    // 第二阶段：完成乘法归约和结果更新
    always @(posedge clk or negedge reset_l) begin
        if (!reset_l) begin
            gf_mult_result <= 0;
        end else if (mult_in_progress) begin
            gf_mult_result <= gf_mult_p2(gf_mult_stage1);
        end
    end
    
    // 更新最终结果
    always @(posedge clk or negedge reset_l) begin
        if (!reset_l) begin
            accumulated <= 0;
            tag_valid <= 0;
            auth_tag <= 0;
        end else if (mult_in_progress) begin
            accumulated <= gf_mult_result;
            tag_valid <= last_block_r;
            if (last_block_r) auth_tag <= combined_data;
        end else begin
            tag_valid <= 0;
        end
    end
endmodule
//SystemVerilog
module cbc_mode_cipher #(parameter BLOCK_SIZE = 32) (
    input wire clk, rst,
    input wire enable, encrypt,
    input wire [BLOCK_SIZE-1:0] iv, data_in, key,
    output reg [BLOCK_SIZE-1:0] data_out,
    output reg valid
);
    // 移动寄存器：将prev_block寄存器分为两部分，一部分直接连接输入
    reg [BLOCK_SIZE-1:0] prev_block_reg;
    reg [BLOCK_SIZE-1:0] key_rotated;
    reg [BLOCK_SIZE-1:0] data_in_reg;
    reg encrypt_reg;
    reg enable_reg;
    
    wire [BLOCK_SIZE-1:0] cipher_in, cipher_out;
    wire [BLOCK_SIZE-1:0] xor_result;
    wire [BLOCK_SIZE-1:0] prev_block;
    
    // 输入端寄存器 - 前向重定时，将寄存器移到靠近输入位置
    always @(posedge clk) begin
        if (rst) begin
            data_in_reg <= {BLOCK_SIZE{1'b0}};
            encrypt_reg <= 1'b0;
            enable_reg <= 1'b0;
        end else begin
            data_in_reg <= data_in;
            encrypt_reg <= encrypt;
            enable_reg <= enable;
        end
    end
    
    // 关键路径寄存器
    always @(posedge clk) begin
        if (rst)
            key_rotated <= 0;
        else
            key_rotated <= {key[7:0], key[31:8]};
    end
    
    // 第二级寄存器 - 保存当前块的状态
    always @(posedge clk) begin
        if (rst)
            prev_block_reg <= iv;
        else if (enable_reg)
            prev_block_reg <= encrypt_reg ? cipher_out : data_in_reg;
    end
    
    // 使用组合逻辑计算prev_block值，降低关键路径延迟
    assign prev_block = (rst) ? iv : prev_block_reg;
    
    // 简化的异或操作
    assign xor_result = data_in_reg ^ prev_block;
    
    // 优化的密码输入选择逻辑
    assign cipher_in = encrypt_reg ? xor_result : data_in_reg;
    
    // 加密功能使用已注册的旋转键
    assign cipher_out = cipher_in ^ key_rotated;
    
    // 并行准备解密输出
    wire [BLOCK_SIZE-1:0] decrypt_out = cipher_out ^ prev_block;
    
    // 输出寄存器逻辑，移动到数据路径末端
    always @(posedge clk) begin
        if (rst) begin
            valid <= 1'b0;
            data_out <= {BLOCK_SIZE{1'b0}};
        end else if (enable_reg) begin
            data_out <= encrypt_reg ? cipher_out : decrypt_out;
            valid <= 1'b1;
        end else begin
            valid <= 1'b0;
        end
    end
endmodule
//SystemVerilog
//IEEE 1364-2005 Verilog
module present_light (
    input wire clk,
    input wire enc_dec,
    input wire [63:0] plaintext,
    output wire [63:0] ciphertext
);
    // 内部连线
    wire [63:0] plaintext_registered;
    wire [79:0] rotated_key;
    
    // 输入寄存器模块实例化
    input_register input_reg_inst (
        .clk(clk),
        .plaintext(plaintext),
        .plaintext_reg(plaintext_registered)
    );
    
    // 密钥旋转模块实例化
    key_rotation key_rot_inst (
        .clk(clk),
        .key_out(rotated_key)
    );
    
    // 加密操作模块实例化
    encryption_operation enc_op_inst (
        .plaintext_reg(plaintext_registered),
        .key_in(rotated_key),
        .ciphertext(ciphertext)
    );
    
endmodule

//IEEE 1364-2005 Verilog
module input_register (
    input wire clk,
    input wire [63:0] plaintext,
    output reg [63:0] plaintext_reg
);
    // 将输入寄存器化，减少输入端到第一级寄存器的延迟
    always @(posedge clk) begin
        plaintext_reg <= plaintext;
    end
endmodule

//IEEE 1364-2005 Verilog
module key_rotation (
    input wire clk,
    output reg [79:0] key_out
);
    // 内部寄存器
    reg [79:0] key_reg;
    
    // 处理密钥旋转
    always @(posedge clk) begin
        key_reg <= {key_reg[18:0], key_reg[79:76]};
        key_out <= {key_reg[18:0], key_reg[79:76]};
    end
endmodule

//IEEE 1364-2005 Verilog
module encryption_operation (
    input wire [63:0] plaintext_reg,
    input wire [79:0] key_in,
    output reg [63:0] ciphertext
);
    // 执行加密XOR操作
    always @(*) begin
        ciphertext = plaintext_reg ^ key_in[63:0];
        // Simplified sBoxLayer and pLayer omitted
    end
endmodule
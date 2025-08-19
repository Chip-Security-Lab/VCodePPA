//SystemVerilog
`timescale 1ns / 1ps
`default_nettype none

module des_key_scheduler #(parameter KEY_WIDTH = 56, KEY_OUT = 48) (
    input wire [KEY_WIDTH-1:0] key_in,
    input wire [5:0] round,
    output wire [KEY_OUT-1:0] subkey
);
    // 内部信号声明
    reg [KEY_WIDTH-1:0] key_temp;
    wire [KEY_WIDTH-1:0] rotated_key;
    wire [19:0] shift_amount; // 新增: 移位量信号
    wire [19:0] negate_round_bit; // 新增: round_bit的补码
    wire [19:0] one_value; // 新增: 常量1
    wire [19:0] two_value; // 新增: 常量2
    wire round_bit;
    
    assign round_bit = round[0];
    
    // 实现二进制补码算法
    assign one_value = 20'h00001; // 常量1
    assign two_value = 20'h00002; // 常量2
    
    // 通过二进制补码计算移位量
    // 当round_bit=0时，shift_amount=2
    // 当round_bit=1时，shift_amount=1
    assign negate_round_bit = {19'b0, round_bit} ^ 20'hFFFFF; // 按位取反
    assign shift_amount = negate_round_bit + one_value; // 加1形成补码
    
    // 使用计算得到的移位量实现移位操作
    always @(*) begin
        if (shift_amount == one_value) begin
            // 左移1位实现
            key_temp = {key_in[KEY_WIDTH-2:0], key_in[KEY_WIDTH-1]};
        end else if (shift_amount == two_value) begin
            // 左移2位实现
            key_temp = {key_in[KEY_WIDTH-3:0], key_in[KEY_WIDTH-1:KEY_WIDTH-2]};
        end else begin
            // 默认情况，虽然在本设计中不会发生
            key_temp = key_in;
        end
    end
    
    // 将临时结果赋值给rotated_key
    assign rotated_key = key_temp;
    
    // 压缩置换 (PC-2 简化版)
    assign subkey = {rotated_key[45:20], rotated_key[19:0], rotated_key[55:46]};
endmodule

`default_nettype wire
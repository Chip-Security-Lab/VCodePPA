//SystemVerilog
// 顶层模块
module decoder_obfuscate #(parameter KEY=8'hA5) (
    input  [7:0]  cipher_addr,
    output [15:0] decoded
);
    wire [7:0]  real_addr;
    wire [15:0] barrel_out;
    wire        enable;
    
    // 地址解密子模块
    address_decryptor #(
        .KEY(KEY)
    ) addr_decrypt_inst (
        .cipher_addr(cipher_addr),
        .real_addr(real_addr)
    );
    
    // 地址验证子模块
    address_validator addr_validate_inst (
        .real_addr(real_addr),
        .enable(enable)
    );
    
    // 桶形移位器子模块
    barrel_shifter barrel_shift_inst (
        .shift_amount(real_addr[3:0]),
        .barrel_out(barrel_out)
    );
    
    // 输出选择子模块
    output_selector out_select_inst (
        .barrel_out(barrel_out),
        .enable(enable),
        .decoded(decoded)
    );
endmodule

// 地址解密子模块
module address_decryptor #(parameter KEY=8'hA5) (
    input  [7:0] cipher_addr,
    output [7:0] real_addr
);
    // 简单异或解密
    assign real_addr = cipher_addr ^ KEY;
endmodule

// 地址验证子模块
module address_validator (
    input  [7:0] real_addr,
    output       enable
);
    // 判断是否在有效范围内
    assign enable = (real_addr < 8'd16);
endmodule

// 桶形移位器子模块
module barrel_shifter (
    input  [3:0]  shift_amount,
    output [15:0] barrel_out
);
    // 初始值为1
    wire [15:0] initial_value = 16'h0001;
    
    // 第一级移位 (移动0或1位)
    wire [15:0] level0 = shift_amount[0] ? {initial_value[14:0], initial_value[15]} : initial_value;
    
    // 第二级移位 (移动0或2位)
    wire [15:0] level1 = shift_amount[1] ? {level0[13:0], level0[15:14]} : level0;
    
    // 第三级移位 (移动0或4位)
    wire [15:0] level2 = shift_amount[2] ? {level1[11:0], level1[15:12]} : level1;
    
    // 第四级移位 (移动0或8位)
    wire [15:0] level3 = shift_amount[3] ? {level2[7:0], level2[15:8]} : level2;
    
    // 最终输出
    assign barrel_out = level3;
endmodule

// 输出选择子模块
module output_selector (
    input  [15:0] barrel_out,
    input         enable,
    output [15:0] decoded
);
    // 当超出范围时输出0
    assign decoded = enable ? barrel_out : 16'h0000;
endmodule
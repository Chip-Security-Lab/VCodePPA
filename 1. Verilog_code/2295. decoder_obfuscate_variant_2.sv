//SystemVerilog
module decoder_obfuscate #(parameter KEY=8'hA5) (
    input [7:0] cipher_addr,
    output [15:0] decoded
);
    wire [7:0] real_addr = cipher_addr ^ KEY;  // 简单异或解密
    wire valid = (real_addr < 16);
    
    // 桶形移位器实现（4级结构）
    wire [15:0] level0;
    wire [15:0] level1;
    wire [15:0] level2;
    wire [15:0] level3;
    
    // 初始化基础值
    assign level0 = 16'h0001;
    
    // 第一级桶形移位：移动0或1位
    assign level1 = real_addr[0] ? {level0[14:0], level0[15]} : level0;
    
    // 第二级桶形移位：移动0或2位
    assign level2 = real_addr[1] ? {level1[13:0], level1[15:14]} : level1;
    
    // 第三级桶形移位：移动0或4位
    assign level3 = real_addr[2] ? {level2[11:0], level2[15:12]} : level2;
    
    // 第四级桶形移位：移动0或8位
    wire [15:0] shifted = real_addr[3] ? {level3[7:0], level3[15:8]} : level3;
    
    // 输出逻辑：如果地址无效则输出0
    assign decoded = valid ? shifted : 16'h0000;
endmodule
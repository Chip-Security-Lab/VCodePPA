//SystemVerilog
// SystemVerilog
module d_latch_preset_clear (
    input wire d,
    input wire enable,
    input wire preset_n, // Active low preset
    input wire clear_n,  // Active low clear
    output reg q,
    // 新增乘法器接口
    input wire [1:0] a,
    input wire [1:0] b,
    output wire [3:0] product
);
    // 使用2位控制信号，将优先级编码到case语句中
    reg [1:0] ctrl;
    
    always @* begin
        // 提取控制信号
        ctrl = {clear_n, preset_n};
        
        // 使用case语句替代if-else级联
        case (ctrl)
            2'b01:   q = 1'b0; // clear_n=0, preset_n=1: 清零优先
            2'b00:   q = 1'b0; // clear_n=0, preset_n=0: 清零优先
            2'b10:   q = 1'b1; // clear_n=1, preset_n=0: 预置为1
            2'b11:   q = enable ? d : q; // clear_n=1, preset_n=1: 正常锁存
            default: q = 1'bx; // 为综合工具优化
        endcase
    end
    
    // 2位Wallace树乘法器实现
    // 部分积生成
    wire [1:0] pp0, pp1;
    assign pp0 = a[0] ? b : 2'b00;
    assign pp1 = a[1] ? {b, 1'b0} : 3'b000;
    
    // Wallace树压缩
    wire [2:0] sum_stage1;    // 第一级和
    wire [2:0] carry_stage1;  // 第一级进位
    
    // 第一级压缩 - 使用半加器和全加器
    assign sum_stage1[0] = pp0[0];
    assign carry_stage1[0] = 1'b0;
    
    // 半加器1
    assign sum_stage1[1] = pp0[1] ^ pp1[0];
    assign carry_stage1[1] = pp0[1] & pp1[0];
    
    // 半加器2
    assign sum_stage1[2] = pp1[1];
    assign carry_stage1[2] = 1'b0;
    
    // 最终加法 - 进位传播加法器
    assign product[0] = sum_stage1[0];
    assign product[1] = sum_stage1[1] ^ carry_stage1[1];
    wire carry_to_bit2 = sum_stage1[1] & carry_stage1[1];
    
    assign product[2] = sum_stage1[2] ^ carry_to_bit2;
    assign product[3] = (sum_stage1[2] & carry_to_bit2) | (pp1[2]);
    
endmodule
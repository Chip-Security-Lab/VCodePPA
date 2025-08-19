//SystemVerilog
module Hybrid_NAND(
    input [1:0] ctrl,
    input [7:0] base,
    output [7:0] res
);
    wire [7:0] shift_val;
    wire [7:0] nand_result;
    
    // 计算移位值 (8'h0F << (ctrl * 4))
    Barrel_Shifter shifter(
        .in(8'h0F),
        .shift_amount({2'b00, ctrl, 1'b0}),  // ctrl*4 实现为 ctrl<<2
        .out(shift_val)
    );
    
    // 执行NAND操作
    assign nand_result = ~(base & shift_val);
    assign res = nand_result;
endmodule

// 桶形移位器模块 - 使用if-else结构替代条件运算符
module Barrel_Shifter(
    input [7:0] in,
    input [4:0] shift_amount,
    output reg [7:0] out
);
    reg [7:0] stage0, stage1, stage2;
    
    always @(*) begin
        // 第一级移位：移动0或1位
        if (shift_amount[0]) begin
            stage0 = {in[6:0], 1'b0};
        end else begin
            stage0 = in;
        end
        
        // 第二级移位：移动0或2位
        if (shift_amount[1]) begin
            stage1 = {stage0[5:0], 2'b00};
        end else begin
            stage1 = stage0;
        end
        
        // 第三级移位：移动0或4位
        if (shift_amount[2]) begin
            stage2 = {stage1[3:0], 4'b0000};
        end else begin
            stage2 = stage1;
        end
        
        // 第四级移位：移动0或8位 (虽然在8位系统中不需要，但为了完整性)
        if (shift_amount[3]) begin
            out = {^stage2, 7'b0000000};
        end else begin
            out = stage2;
        end
    end
endmodule
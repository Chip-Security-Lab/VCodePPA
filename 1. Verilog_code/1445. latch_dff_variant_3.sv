//SystemVerilog
module latch_dff (
    input wire clk,
    input wire en,
    input wire d,
    output reg q
);

    // 中间流水线寄存器
    reg d_stage1;
    reg en_stage1;
    reg d_stage2;
    
    // 第一级流水线：捕获输入
    always @(posedge clk) begin
        d_stage1 <= d;
        en_stage1 <= en;
    end
    
    // 第二级流水线：锁存逻辑
    always @(posedge clk) begin
        if (en_stage1)
            d_stage2 <= d_stage1;
    end
    
    // 第三级流水线：输出寄存
    always @(posedge clk) begin
        q <= d_stage2;
    end

endmodule
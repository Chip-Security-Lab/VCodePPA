//SystemVerilog
module rom_thermometer #(
    parameter N = 8
)(
    input wire clk,         // 增加时钟输入用于流水线寄存器
    input wire rst_n,       // 增加复位信号
    input wire [2:0] val,   // 3位输入值
    output reg [N-1:0] code // N位温度计编码输出
);
    // 内部信号定义
    reg [2:0] val_stage1;    // 第一级流水线寄存器
    reg [N-1:0] mask_stage1; // 掩码中间结果
    reg [N-1:0] code_stage2; // 第二级流水线寄存器
    
    // 第一级流水线 - 寄存输入并生成掩码
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            val_stage1 <= 3'b0;
            mask_stage1 <= {N{1'b0}};
        end else begin
            val_stage1 <= val;
            mask_stage1 <= (1'b1 << val);
        end
    end
    
    // 第二级流水线 - 计算最终的温度计编码
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            code_stage2 <= {N{1'b0}};
        end else begin
            code_stage2 <= mask_stage1 - 1'b1;
        end
    end
    
    // 输出赋值
    always @(*) begin
        code = code_stage2;
    end
    
endmodule
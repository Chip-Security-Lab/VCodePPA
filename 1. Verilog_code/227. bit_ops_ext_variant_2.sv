//SystemVerilog
module bit_ops_ext (
    input wire clk,               // 时钟输入
    input wire rst_n,             // 复位信号
    input wire [3:0] src1,        // 源操作数1
    input wire [3:0] src2,        // 源操作数2
    output reg [3:0] concat,      // 拼接结果
    output reg [3:0] reverse      // 反转结果
);
    // 优化的流水线寄存器声明
    reg [1:0] src1_l;             // src1的低2位
    reg [1:0] src2_l;             // src2的低2位
    reg [3:0] src1_reversed;      // 预计算的src1反转值
    
    // 第一级流水线 - 预计算和寄存
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            src1_l <= 2'b00;
            src2_l <= 2'b00;
            src1_reversed <= 4'b0000;
        end else begin
            src1_l <= src1[1:0];
            src2_l <= src2[1:0];
            // 预计算反转操作，减少第二级逻辑延迟
            src1_reversed <= {src1[0], src1[1], src1[2], src1[3]};
        end
    end
    
    // 第二级流水线 - 直接使用预计算的值
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            concat <= 4'b0000;
            reverse <= 4'b0000;
        end else begin
            // 直接使用第一级的寄存器值进行拼接
            concat <= {src1_l, src2_l};
            // 使用预计算的反转值
            reverse <= src1_reversed;
        end
    end
    
endmodule
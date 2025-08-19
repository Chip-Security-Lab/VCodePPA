//SystemVerilog
module LowPower_Hamming_Codec(
    input clk,
    input power_save_en,
    input [15:0] data_in,
    output [15:0] data_out
);
    // 使用时钟使能而非时钟门控，减少门级延迟
    wire clk_en = ~power_save_en;
    
    // 前向重定时: 将计算分解并移动寄存器
    reg [15:0] data_in_reg;
    reg [4:0] parity_reg;
    reg [15:0] encoded_reg;
    
    // 第一级寄存：捕获输入数据
    always @(posedge clk) begin
        if (clk_en) begin
            data_in_reg <= data_in;
        end
    end
    
    // 第二级寄存：存储计算的校验位
    always @(posedge clk) begin
        if (clk_en) begin
            parity_reg[0] <= ^(data_in_reg & 16'hAAAA);
            parity_reg[1] <= ^(data_in_reg & 16'hCCCC);
            parity_reg[2] <= ^(data_in_reg & 16'hF0F0);
            parity_reg[3] <= ^(data_in_reg & 16'hFF00);
            parity_reg[4] <= ^{data_in_reg, parity_reg[3:0]}; // 总校验位
        end
    end
    
    // 第三级寄存：组装最终输出
    always @(posedge clk) begin
        if (clk_en) begin
            encoded_reg <= {data_in_reg[15:5], parity_reg[4], data_in_reg[4:0], parity_reg[3:0]};
        end
    end
    
    // 将输出直接连接到寄存器
    assign data_out = encoded_reg;
    
endmodule
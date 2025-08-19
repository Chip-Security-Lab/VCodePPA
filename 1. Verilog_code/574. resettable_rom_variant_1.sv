//SystemVerilog
module resettable_rom (
    input clk,
    input rst,  // 复位信号
    input [3:0] addr,
    output reg [7:0] data
);
    // ROM存储器定义
    reg [7:0] rom [0:15];
    
    // 流水线寄存器
    reg [3:0] addr_stage1;
    reg [7:0] data_stage2;
    
    // ROM初始化
    initial begin
        rom[0] = 8'h12; rom[1] = 8'h34; rom[2] = 8'h56; rom[3] = 8'h78;
        rom[4] = 8'h9A; rom[5] = 8'hBC; rom[6] = 8'hDE; rom[7] = 8'hF0;
        rom[8] = 8'h11; rom[9] = 8'h22; rom[10] = 8'h33; rom[11] = 8'h44;
        rom[12] = 8'h55; rom[13] = 8'h66; rom[14] = 8'h77; rom[15] = 8'h88;
    end
    
    // 第一级流水线：地址寄存
    always @(posedge clk or posedge rst) begin
        if (rst)
            addr_stage1 <= 4'h0;
        else
            addr_stage1 <= addr;
    end
    
    // 第二级流水线：ROM读取
    always @(posedge clk or posedge rst) begin
        if (rst)
            data_stage2 <= 8'h00;
        else
            data_stage2 <= rom[addr_stage1];
    end
    
    // 第三级流水线：输出寄存
    always @(posedge clk or posedge rst) begin
        if (rst)
            data <= 8'h00;
        else
            data <= data_stage2;
    end
endmodule
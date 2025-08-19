//SystemVerilog
module rom_case #(parameter DW=8, AW=4)(
    input clk,
    input [AW-1:0] addr,
    output reg [DW-1:0] data
);
    // 存储器内容的寄存器定义 - 提前声明所有可能值
    reg [DW-1:0] mem_lower_half [0:7];  // 存储地址0-7的数据
    reg [DW-1:0] mem_upper_half [0:7];  // 存储地址8-F的数据
    wire addr_select;                    // 用于选择上半区或下半区
    
    // 初始化ROM内容 - 仅在复位时更新
    initial begin
        // 下半区内容初始化
        mem_lower_half[0] = 8'h00;
        mem_lower_half[1] = 8'h11;
        mem_lower_half[2] = 8'h22;
        mem_lower_half[3] = 8'h33;
        mem_lower_half[4] = 8'h44;
        mem_lower_half[5] = 8'h55;
        mem_lower_half[6] = 8'h66;
        mem_lower_half[7] = 8'h77;
        
        // 上半区内容初始化
        mem_upper_half[0] = 8'h88;
        mem_upper_half[1] = 8'h99;
        mem_upper_half[2] = 8'hAA;
        mem_upper_half[3] = 8'hBB;
        mem_upper_half[4] = 8'hCC;
        mem_upper_half[5] = 8'hDD;
        mem_upper_half[6] = 8'hEE;
        mem_upper_half[7] = 8'hFF;
    end
    
    // 地址解码逻辑 - 确定是上半区还是下半区
    assign addr_select = addr[3];  // MSB用于区分上半区和下半区
    
    // 数据读取逻辑 - 基于时钟沿更新输出数据
    always @(posedge clk) begin
        data <= addr_select ? mem_upper_half[addr[2:0]] : mem_lower_half[addr[2:0]];
    end
endmodule
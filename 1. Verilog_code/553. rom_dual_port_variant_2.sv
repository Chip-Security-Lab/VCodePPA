//SystemVerilog
module rom_dual_port #(parameter W=32, D=1024)(
    input clk,
    input [9:0] addr1,
    input [9:0] addr2,
    output reg [W-1:0] dout1,
    output reg [W-1:0] dout2
);
    // 声明双端口ROM存储器
    (* ram_style = "block" *) reg [W-1:0] content [0:D-1];
    
    // 初始化一些值用于测试
    initial begin
        // 示例初始化，实际使用时应替换为具体值
        content[0] = 32'h00001111;
        content[1] = 32'h22223333;
        // $readmemh("dual_port.init", content); // 仿真中使用
    end
    
    // 读取地址寄存器
    reg [9:0] addr1_reg, addr2_reg;
    
    // 地址寄存并读取操作，采用两阶段流水线以提高时序性能
    always @(posedge clk) begin
        addr1_reg <= addr1;
        addr2_reg <= addr2;
        dout1 <= content[addr1_reg];
        dout2 <= content[addr2_reg];
    end
endmodule
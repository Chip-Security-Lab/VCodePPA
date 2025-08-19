module rom_dual_port #(parameter W=32, D=1024)(
    input clk,
    input [9:0] addr1,
    input [9:0] addr2,
    output reg [W-1:0] dout1,
    output reg [W-1:0] dout2
);
    // 声明双端口ROM存储器
    reg [W-1:0] content [0:D-1];
    
    // 初始化一些值用于测试
    initial begin
        // 示例初始化，实际使用时应替换为具体值
        content[0] = 32'h00001111;
        content[1] = 32'h22223333;
        // $readmemh("dual_port.init", content); // 仿真中使用
    end
    
    // 两个端口的读取操作
    always @(posedge clk) begin
        dout1 <= content[addr1];
        dout2 <= content[addr2];
    end
endmodule
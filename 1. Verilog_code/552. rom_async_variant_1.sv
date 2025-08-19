//SystemVerilog
module rom_async #(parameter DATA=16, ADDR=8)(
    input [ADDR-1:0] a,
    output reg [DATA-1:0] dout
);
    // 声明存储器
    reg [DATA-1:0] mem [(1<<ADDR)-1:0];
    
    // 使用桶形移位器结构实现地址映射
    wire [ADDR-1:0] addr_mux [0:ADDR-1];
    
    genvar i;
    generate
        for (i = 0; i < ADDR; i = i + 1) begin : mux_gen
            assign addr_mux[i] = a >> i; // 通过右移实现地址选择
        end
    endgenerate
    
    always @(*) begin
        dout = mem[addr_mux[0]] | mem[addr_mux[1]] | mem[addr_mux[2]] | mem[addr_mux[3]]; // 根据移位选择输出
    end
    
    // 初始化内容
    initial begin
        integer i;
        // 先将所有内存位置初始化为0，避免未定义状态
        for (i = 0; i < (1<<ADDR); i = i + 1) begin
            mem[i] = {DATA{1'b0}};
        end
        
        // 然后设置具体数据
        mem[0] = 16'h1234;
        mem[1] = 16'h5678;
        mem[2] = 16'h9ABC;
        mem[3] = 16'hDEF0;
        // 其余地址保持为0
    end
endmodule
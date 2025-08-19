module rom_async #(parameter DATA=16, ADDR=8)(
    input [ADDR-1:0] a,
    output [DATA-1:0] dout
);
    // 声明存储器
    reg [DATA-1:0] mem [(1<<ADDR)-1:0];
    
    // 读取操作
    assign dout = mem[a];
    
    // 初始化内容 - 直接在代码中初始化部分内容
    // 对于综合，可以替换$readmemh为直接赋值
    initial begin
        // 示例初始化，实际使用时应替换为具体值
        mem[0] = 16'h1234;
        mem[1] = 16'h5678;
        mem[2] = 16'h9ABC;
        mem[3] = 16'hDEF0;
        // 为简化，仅初始化部分内容
        // $readmemh("init_data.hex", mem); // 仿真中使用
    end
endmodule
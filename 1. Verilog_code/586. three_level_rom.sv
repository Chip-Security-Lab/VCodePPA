module three_level_rom (
    input clk,
    input [3:0] addr,
    output reg [7:0] data
);
    reg [7:0] cache [0:3]; // 小型缓存
    reg [7:0] rom [0:15];  // 真实ROM存储

    initial begin
        rom[0] = 8'h77; rom[1] = 8'h88;
    end

    always @(posedge clk) begin
        cache[addr[1:0]] <= rom[addr]; // 模拟缓存层
        data <= cache[addr[1:0]];
    end
endmodule

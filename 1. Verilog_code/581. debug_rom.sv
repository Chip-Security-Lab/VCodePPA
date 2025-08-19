module debug_rom (
    input clk,
    input [3:0] addr,
    input debug_en,  // 调试模式开关
    output reg [7:0] data,
    output reg [3:0] debug_addr  // 当前访问的地址
);
    reg [7:0] rom [0:15];

    initial begin
        rom[0] = 8'h12; rom[1] = 8'h34;
    end

    always @(posedge clk) begin
        if (debug_en)
            debug_addr <= addr; // 记录访问地址
        data <= rom[addr];
    end
endmodule

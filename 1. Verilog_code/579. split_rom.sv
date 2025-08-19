module split_rom (
    input clk,
    input [3:0] addr,
    output reg [15:0] data // 两个ROM合并输出
);
    reg [7:0] rom0 [0:15];
    reg [7:0] rom1 [0:15];

    initial begin
        rom0[0] = 8'h12; rom0[1] = 8'h34;
        rom1[0] = 8'hAB; rom1[1] = 8'hCD;
    end

    always @(posedge clk) begin
        data <= {rom1[addr], rom0[addr]}; // 高位和低位拼接
    end
endmodule

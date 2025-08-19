module hybrid_rom (
    input clk,
    input we,  // 写使能
    input [3:0] addr,
    input [7:0] din,
    output reg [7:0] data
);
    reg [7:0] rom [0:7]; // 只读部分
    reg [7:0] ram [8:15]; // 可更新部分

    initial begin
        rom[0] = 8'hEE; rom[1] = 8'hFF;
    end

    always @(posedge clk) begin
        if (addr < 8)
            data <= rom[addr]; // 只读区域
        else if (we)
            ram[addr] <= din;  // 可更新区域
        else
            data <= ram[addr];
    end
endmodule

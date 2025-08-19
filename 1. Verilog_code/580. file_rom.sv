module file_rom (
    input clk,
    input [3:0] addr,
    output reg [7:0] data
);
    reg [7:0] rom [0:15];

    initial begin
        $readmemh("rom_data.hex", rom); // 从文件加载数据
    end

    always @(posedge clk) begin
        data <= rom[addr];
    end
endmodule

module crc_rom (
    input clk,
    input [3:0] addr,
    output reg [7:0] data,
    output reg crc_error
);
    reg [7:0] rom [0:15];
    reg [3:0] crc [0:15];

    initial begin
        rom[0] = 8'h99; crc[0] = 4'hF;  // 预存数据和CRC值
    end

    always @(posedge clk) begin
        data <= rom[addr];
        crc_error <= (^rom[addr]) != crc[addr]; // 简单的CRC校验
    end
endmodule

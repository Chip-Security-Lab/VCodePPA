module parity_rom (
    input [3:0] addr,
    output reg [7:0] data,
    output reg parity_error
);
    reg [8:0] rom [0:15]; // 包含1位奇偶校验

    initial begin
        rom[0] = 9'b000100010; // Data = 0x12, Parity = 0
        rom[1] = 9'b001101000; // Data = 0x34, Parity = 0
        rom[2] = 9'b010101101; // Data = 0x56, Parity = 1
        rom[3] = 9'b011110000; // Data = 0x78, Parity = 0
    end

    always @(*) begin
        data = rom[addr][7:0];
        parity_error = (rom[addr][8] != ^data);  // 奇偶校验错误检测
    end
endmodule

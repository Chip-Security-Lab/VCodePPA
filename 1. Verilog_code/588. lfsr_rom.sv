module lfsr_rom (
    input clk,
    input rst,
    output reg [3:0] addr,
    output reg [7:0] data
);
    reg [7:0] rom [0:15];

    initial begin
        rom[0] = 8'hA0; rom[1] = 8'hB1;
    end

    always @(posedge clk or posedge rst) begin
        if (rst)
            addr <= 4'b1010;
        else
            addr <= {addr[2:0], addr[3] ^ addr[2]}; // LFSR 生成地址
        data <= rom[addr];
    end
endmodule

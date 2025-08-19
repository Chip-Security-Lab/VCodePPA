//SystemVerilog
module priority_rom (
    input clk,
    input [3:0] addr_high,
    input [3:0] addr_low,
    input high_priority,
    output reg [7:0] data
);
    reg [7:0] rom [0:15];
    reg [3:0] addr_reg;
    reg [7:0] rom_data_reg;

    initial begin
        rom[0] = 8'h55; rom[1] = 8'h66;
    end

    always @(posedge clk) begin
        addr_reg <= high_priority ? addr_high : addr_low;
        rom_data_reg <= rom[addr_reg];
        data <= rom_data_reg;
    end
endmodule
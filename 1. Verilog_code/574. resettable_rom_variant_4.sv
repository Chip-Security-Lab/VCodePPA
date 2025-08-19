//SystemVerilog
module resettable_rom (
    input clk,
    input rst,  // 复位信号
    input [3:0] addr,
    output reg [7:0] data
);
    // ROM memory declaration
    reg [7:0] rom [0:15];
    
    // Pipeline registers for address and ROM data
    reg [3:0] addr_pipe;
    reg [7:0] rom_data_pipe;

    // ROM initialization
    initial begin
        rom[0] = 8'h12; rom[1] = 8'h34; rom[2] = 8'h56; rom[3] = 8'h78;
        rom[4] = 8'h9A; rom[5] = 8'hBC; rom[6] = 8'hDE; rom[7] = 8'hF0;
        rom[8] = 8'h11; rom[9] = 8'h22; rom[10] = 8'h33; rom[11] = 8'h44;
        rom[12] = 8'h55; rom[13] = 8'h66; rom[14] = 8'h77; rom[15] = 8'h88;
    end

    // First pipeline stage: register address
    always @(posedge clk or posedge rst) begin
        if (rst)
            addr_pipe <= 4'h0;
        else
            addr_pipe <= addr;
    end

    // Second pipeline stage: ROM read and output
    always @(posedge clk or posedge rst) begin
        if (rst) begin
            rom_data_pipe <= 8'h00;
            data <= 8'h00;
        end
        else begin
            rom_data_pipe <= rom[addr_pipe];
            data <= rom_data_pipe;
        end
    end
endmodule
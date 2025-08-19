//SystemVerilog
module debug_rom (
    input clk,
    input [3:0] addr,
    input debug_en,
    output [7:0] data,
    output [3:0] debug_addr
);
    wire [7:0] rom_data;
    
    rom_memory memory_unit (
        .clk(clk),
        .addr(addr),
        .data(rom_data)
    );
    
    output_control control_unit (
        .clk(clk),
        .addr(addr),
        .debug_en(debug_en),
        .rom_data(rom_data),
        .data(data),
        .debug_addr(debug_addr)
    );
endmodule

module rom_memory (
    input clk,
    input [3:0] addr,
    output reg [7:0] data
);
    (* ram_style = "distributed" *) reg [7:0] rom [0:15];
    
    initial begin
        rom[0] = 8'h12; rom[1] = 8'h34;
        rom[2] = 8'h00; rom[3] = 8'h00;
        rom[4] = 8'h00; rom[5] = 8'h00;
        rom[6] = 8'h00; rom[7] = 8'h00;
        rom[8] = 8'h00; rom[9] = 8'h00;
        rom[10] = 8'h00; rom[11] = 8'h00;
        rom[12] = 8'h00; rom[13] = 8'h00;
        rom[14] = 8'h00; rom[15] = 8'h00;
    end
    
    always @(posedge clk) begin
        data <= rom[addr];
    end
endmodule

module output_control (
    input clk,
    input [3:0] addr,
    input debug_en,
    input [7:0] rom_data,
    output reg [7:0] data,
    output reg [3:0] debug_addr
);
    always @(posedge clk) begin
        data <= rom_data;
        if (debug_en)
            debug_addr <= addr;
    end
endmodule
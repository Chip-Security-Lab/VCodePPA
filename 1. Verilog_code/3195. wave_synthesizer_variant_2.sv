//SystemVerilog
module wave_synthesizer #(
    parameter ADDR_WIDTH = 8,
    parameter DATA_WIDTH = 8
)(
    input clk,
    output [DATA_WIDTH-1:0] wave
);

// 地址计数器模块
addr_counter #(
    .ADDR_WIDTH(ADDR_WIDTH)
) addr_counter_inst (
    .clk(clk),
    .addr(addr)
);

// 正弦波查找表模块
sine_rom #(
    .ADDR_WIDTH(ADDR_WIDTH),
    .DATA_WIDTH(DATA_WIDTH)
) sine_rom_inst (
    .addr(addr),
    .data(wave)
);

endmodule

module addr_counter #(
    parameter ADDR_WIDTH = 8
)(
    input clk,
    output reg [ADDR_WIDTH-1:0] addr
);

always @(posedge clk) begin
    addr <= addr + 1;
end

endmodule

module sine_rom #(
    parameter ADDR_WIDTH = 8,
    parameter DATA_WIDTH = 8
)(
    input [ADDR_WIDTH-1:0] addr,
    output reg [DATA_WIDTH-1:0] data
);

reg [DATA_WIDTH-1:0] rom [0:2**ADDR_WIDTH-1];
initial $readmemh("sine_table.hex", rom);

always @(*) begin
    data = rom[addr];
end

endmodule
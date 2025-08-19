module wave_synthesizer #(
    parameter ADDR_WIDTH = 8,
    parameter DATA_WIDTH = 8
)(
    input clk,
    output reg [DATA_WIDTH-1:0] wave
);
reg [ADDR_WIDTH-1:0] addr_counter;

// 预定义正弦波查找表
reg [DATA_WIDTH-1:0] sine_rom [0:2**ADDR_WIDTH-1];
initial $readmemh("sine_table.hex", sine_rom);

always @(posedge clk) begin
    addr_counter <= addr_counter + 1;
    wave <= sine_rom[addr_counter];
end
endmodule

module sram_ecc #(
    parameter DATA_WIDTH = 32
)(
    input clk,
    input we,
    input [6:0] addr,
    input [DATA_WIDTH-1:0] din,
    output [DATA_WIDTH-1:0] dout,
    output [6:0] syndrome
);
localparam ECC_WIDTH = $clog2(DATA_WIDTH)+1;
localparam TOTAL_WIDTH = DATA_WIDTH + ECC_WIDTH;

wire [TOTAL_WIDTH-1:0] encoded;
reg [TOTAL_WIDTH-1:0] mem [0:127];

// Hamming encoder
assign encoded[DATA_WIDTH-1:0] = din;
assign encoded[DATA_WIDTH+:ECC_WIDTH] = ^(din & 32'h69966996);

always @(posedge clk) begin
    if (we) mem[addr] <= encoded;
end

// Error detection
wire [TOTAL_WIDTH-1:0] read_data = mem[addr];
assign dout = read_data[DATA_WIDTH-1:0];
assign syndrome = read_data[DATA_WIDTH+:ECC_WIDTH] ^ ^(read_data[DATA_WIDTH-1:0] & 32'h69966996);
endmodule

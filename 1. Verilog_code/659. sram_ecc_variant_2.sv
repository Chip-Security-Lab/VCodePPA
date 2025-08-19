//SystemVerilog
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

// LUT-based Hamming encoder
wire [ECC_WIDTH-1:0] ecc_bits;
wire [3:0] lut_in [0:5];
wire [0:0] lut_out [0:5];

// LUT inputs
assign lut_in[0] = {din[3], din[2], din[1], din[0]};
assign lut_in[1] = {din[7], din[6], din[5], din[4]};
assign lut_in[2] = {din[11], din[10], din[9], din[8]};
assign lut_in[3] = {din[15], din[14], din[13], din[12]};
assign lut_in[4] = {din[19], din[18], din[17], din[16]};
assign lut_in[5] = {din[23], din[22], din[21], din[20]};

// LUT outputs
assign lut_out[0] = ^lut_in[0];
assign lut_out[1] = ^lut_in[1];
assign lut_out[2] = ^lut_in[2];
assign lut_out[3] = ^lut_in[3];
assign lut_out[4] = ^lut_in[4];
assign lut_out[5] = ^lut_in[5];

// Combine LUT outputs
assign ecc_bits[0] = lut_out[0] ^ lut_out[1] ^ lut_out[2] ^ lut_out[3];
assign ecc_bits[1] = lut_out[0] ^ lut_out[1] ^ lut_out[4] ^ lut_out[5];
assign ecc_bits[2] = lut_out[0] ^ lut_out[2] ^ lut_out[4];
assign ecc_bits[3] = lut_out[1] ^ lut_out[2] ^ lut_out[5];
assign ecc_bits[4] = lut_out[3] ^ lut_out[4] ^ lut_out[5];
assign ecc_bits[5] = lut_out[0] ^ lut_out[1] ^ lut_out[2] ^ lut_out[3] ^ lut_out[4] ^ lut_out[5];

assign encoded[DATA_WIDTH-1:0] = din;
assign encoded[DATA_WIDTH+:ECC_WIDTH] = ecc_bits;

always @(posedge clk) begin
    if (we) mem[addr] <= encoded;
end

// LUT-based error detection
wire [TOTAL_WIDTH-1:0] read_data = mem[addr];
wire [DATA_WIDTH-1:0] data = read_data[DATA_WIDTH-1:0];
wire [ECC_WIDTH-1:0] stored_ecc = read_data[DATA_WIDTH+:ECC_WIDTH];

wire [ECC_WIDTH-1:0] computed_ecc;
wire [3:0] det_lut_in [0:5];
wire [0:0] det_lut_out [0:5];

// Detection LUT inputs
assign det_lut_in[0] = {data[3], data[2], data[1], data[0]};
assign det_lut_in[1] = {data[7], data[6], data[5], data[4]};
assign det_lut_in[2] = {data[11], data[10], data[9], data[8]};
assign det_lut_in[3] = {data[15], data[14], data[13], data[12]};
assign det_lut_in[4] = {data[19], data[18], data[17], data[16]};
assign det_lut_in[5] = {data[23], data[22], data[21], data[20]};

// Detection LUT outputs
assign det_lut_out[0] = ^det_lut_in[0];
assign det_lut_out[1] = ^det_lut_in[1];
assign det_lut_out[2] = ^det_lut_in[2];
assign det_lut_out[3] = ^det_lut_in[3];
assign det_lut_out[4] = ^det_lut_in[4];
assign det_lut_out[5] = ^det_lut_in[5];

// Combine detection LUT outputs
assign computed_ecc[0] = det_lut_out[0] ^ det_lut_out[1] ^ det_lut_out[2] ^ det_lut_out[3];
assign computed_ecc[1] = det_lut_out[0] ^ det_lut_out[1] ^ det_lut_out[4] ^ det_lut_out[5];
assign computed_ecc[2] = det_lut_out[0] ^ det_lut_out[2] ^ det_lut_out[4];
assign computed_ecc[3] = det_lut_out[1] ^ det_lut_out[2] ^ det_lut_out[5];
assign computed_ecc[4] = det_lut_out[3] ^ det_lut_out[4] ^ det_lut_out[5];
assign computed_ecc[5] = det_lut_out[0] ^ det_lut_out[1] ^ det_lut_out[2] ^ det_lut_out[3] ^ det_lut_out[4] ^ det_lut_out[5];

assign dout = data;
assign syndrome = stored_ecc ^ computed_ecc;

endmodule
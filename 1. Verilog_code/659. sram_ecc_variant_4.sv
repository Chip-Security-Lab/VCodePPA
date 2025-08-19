//SystemVerilog
module sram_ecc #(
    parameter DATA_WIDTH = 32
)(
    input clk,
    input rst_n,
    input we,
    input [6:0] addr,
    input [DATA_WIDTH-1:0] din,
    output [DATA_WIDTH-1:0] dout,
    output [6:0] syndrome,
    output valid
);

localparam ECC_WIDTH = $clog2(DATA_WIDTH)+1;
localparam TOTAL_WIDTH = DATA_WIDTH + ECC_WIDTH;

// Stage 1: Input and Encoding
reg [6:0] addr_stage1;
reg [DATA_WIDTH-1:0] din_stage1;
reg we_stage1;
reg valid_stage1;

wire [DATA_WIDTH-1:0] din_xor = din_stage1 & 32'h69966996;
wire [ECC_WIDTH-1:0] ecc_bits;
genvar i;
generate
    for(i=0; i<ECC_WIDTH; i=i+1) begin : gen_ecc
        assign ecc_bits[i] = ^(din_xor & (32'h69966996 >> i));
    end
endgenerate

wire [TOTAL_WIDTH-1:0] encoded = {ecc_bits, din_stage1};

// Stage 2: Memory Access
reg [6:0] addr_stage2;
reg we_stage2;
reg valid_stage2;
reg [TOTAL_WIDTH-1:0] mem [0:127];
reg [TOTAL_WIDTH-1:0] read_data_stage2;

// Stage 3: Error Detection
reg [TOTAL_WIDTH-1:0] read_data_stage3;
reg valid_stage3;
wire [DATA_WIDTH-1:0] data_xor = read_data_stage3[DATA_WIDTH-1:0] & 32'h69966996;
wire [ECC_WIDTH-1:0] calc_syndrome;
generate
    for(i=0; i<ECC_WIDTH; i=i+1) begin : gen_syndrome
        assign calc_syndrome[i] = ^(data_xor & (32'h69966996 >> i));
    end
endgenerate

// Pipeline Control
always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
        valid_stage1 <= 1'b0;
        valid_stage2 <= 1'b0;
        valid_stage3 <= 1'b0;
    end else begin
        valid_stage1 <= 1'b1;
        valid_stage2 <= valid_stage1;
        valid_stage3 <= valid_stage2;
    end
end

// Stage 1 Registers
always @(posedge clk) begin
    addr_stage1 <= addr;
    din_stage1 <= din;
    we_stage1 <= we;
end

// Stage 2 Registers and Memory
always @(posedge clk) begin
    addr_stage2 <= addr_stage1;
    we_stage2 <= we_stage1;
    if (we_stage1) begin
        mem[addr_stage1] <= encoded;
    end
    read_data_stage2 <= mem[addr_stage1];
end

// Stage 3 Registers
always @(posedge clk) begin
    read_data_stage3 <= read_data_stage2;
end

// Outputs
assign dout = read_data_stage3[DATA_WIDTH-1:0];
assign syndrome = read_data_stage3[DATA_WIDTH+:ECC_WIDTH] ^ calc_syndrome;
assign valid = valid_stage3;

endmodule
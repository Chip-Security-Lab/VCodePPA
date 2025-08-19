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

// Pipeline stages
reg [DATA_WIDTH-1:0] din_reg;
reg [6:0] addr_reg;
reg we_reg;

// Memory array
reg [TOTAL_WIDTH-1:0] mem [0:127];

// ECC encoder pipeline
reg [ECC_WIDTH-1:0] ecc_bits_reg;
reg [ECC_WIDTH-1:0] ecc_result_reg;
reg [TOTAL_WIDTH-1:0] encoded_reg;

// ECC decoder pipeline
reg [TOTAL_WIDTH-1:0] read_data_reg;
reg [ECC_WIDTH-1:0] check_bits_reg;
reg [ECC_WIDTH-1:0] check_result_reg;

// Input pipeline stage
always @(posedge clk) begin
    din_reg <= din;
    addr_reg <= addr;
    we_reg <= we;
end

// ECC encoder stage 1: Calculate parity bits
always @(posedge clk) begin
    ecc_bits_reg <= ^(din_reg & 32'h69966996);
end

// ECC encoder stage 2: Calculate final ECC
always @(posedge clk) begin
    ecc_result_reg <= ecc_bits_reg;
end

// Memory write stage
always @(posedge clk) begin
    if (we_reg) begin
        encoded_reg <= {ecc_result_reg, din_reg};
        mem[addr_reg] <= encoded_reg;
    end
end

// Memory read stage
always @(posedge clk) begin
    read_data_reg <= mem[addr_reg];
end

// ECC decoder stage 1: Calculate check bits
always @(posedge clk) begin
    check_bits_reg <= ^(read_data_reg[DATA_WIDTH-1:0] & 32'h69966996);
end

// ECC decoder stage 2: Calculate syndrome
always @(posedge clk) begin
    check_result_reg <= check_bits_reg;
end

// Output assignments
assign dout = read_data_reg[DATA_WIDTH-1:0];
assign syndrome = read_data_reg[DATA_WIDTH+:ECC_WIDTH] ^ check_result_reg;

endmodule
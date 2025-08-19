//SystemVerilog
module tdp_ram_basic #(
    parameter DATA_WIDTH = 8,
    parameter ADDR_WIDTH = 6,
    parameter DEPTH = 64
)(
    input clk,
    // Port A
    input [ADDR_WIDTH-1:0] addr_a,
    input [DATA_WIDTH-1:0] din_a,
    output reg [DATA_WIDTH-1:0] dout_a,
    input we_a,
    // Port B
    input [ADDR_WIDTH-1:0] addr_b,
    input [DATA_WIDTH-1:0] din_b,
    output reg [DATA_WIDTH-1:0] dout_b,
    input we_b
);

// Memory array
reg [DATA_WIDTH-1:0] mem [0:DEPTH-1];

// Port A pipeline registers
reg [ADDR_WIDTH-1:0] addr_a_reg;
reg [DATA_WIDTH-1:0] din_a_reg;
reg we_a_reg;

// Port B pipeline registers
reg [ADDR_WIDTH-1:0] addr_b_reg;
reg [DATA_WIDTH-1:0] din_b_reg;
reg we_b_reg;

// Port A address and control pipeline
always @(posedge clk) begin
    addr_a_reg <= addr_a;
    din_a_reg <= din_a;
    we_a_reg <= we_a;
end

// Port B address and control pipeline
always @(posedge clk) begin
    addr_b_reg <= addr_b;
    din_b_reg <= din_b;
    we_b_reg <= we_b;
end

// Port A memory access
always @(posedge clk) begin
    if (we_a_reg) begin
        mem[addr_a_reg] <= din_a_reg;
        dout_a <= din_a_reg;
    end else begin
        dout_a <= mem[addr_a_reg];
    end
end

// Port B memory access
always @(posedge clk) begin
    if (we_b_reg) begin
        mem[addr_b_reg] <= din_b_reg;
        dout_b <= din_b_reg;
    end else begin
        dout_b <= mem[addr_b_reg];
    end
end

endmodule
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

reg [DATA_WIDTH-1:0] mem [0:DEPTH-1];

// Port A operation
always @(posedge clk) begin
    if (we_a) begin
        mem[addr_a] <= din_a;
        dout_a <= din_a; // Write-first behavior
    end else begin
        dout_a <= mem[addr_a];
    end
end

// Port B operation
always @(posedge clk) begin
    if (we_b) begin
        mem[addr_b] <= din_b;
        dout_b <= din_b;
    end else begin
        dout_b <= mem[addr_b];
    end
end
endmodule

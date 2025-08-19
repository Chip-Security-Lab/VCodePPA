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

// Pipeline registers for addressing and control
reg [ADDR_WIDTH-1:0] addr_a_pipe, addr_b_pipe;
reg [DATA_WIDTH-1:0] din_a_pipe, din_b_pipe;
reg we_a_pipe, we_b_pipe;

// Combined pipeline and memory access operations
always @(posedge clk) begin
    // Pipeline stage 1: Register inputs
    addr_a_pipe <= addr_a;
    addr_b_pipe <= addr_b;
    din_a_pipe <= din_a;
    din_b_pipe <= din_b;
    we_a_pipe <= we_a;
    we_b_pipe <= we_b;

    // Pipeline stage 2: Memory access - Port A
    if (we_a_pipe) begin
        mem[addr_a_pipe] <= din_a_pipe;
        dout_a <= din_a_pipe;
    end else begin
        dout_a <= mem[addr_a_pipe];
    end

    // Pipeline stage 2: Memory access - Port B
    if (we_b_pipe) begin
        mem[addr_b_pipe] <= din_b_pipe;
        dout_b <= din_b_pipe;
    end else begin
        dout_b <= mem[addr_b_pipe];
    end
end

endmodule
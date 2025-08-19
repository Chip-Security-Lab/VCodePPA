//SystemVerilog
module sync_dual_port_ram_with_depth #(
    parameter DATA_WIDTH = 8,
    parameter ADDR_WIDTH = 8,
    parameter RAM_DEPTH = 256
)(
    input wire clk,
    input wire rst,
    input wire we_a, we_b,
    input wire [ADDR_WIDTH-1:0] addr_a, addr_b,
    input wire [DATA_WIDTH-1:0] din_a, din_b,
    output reg [DATA_WIDTH-1:0] dout_a, dout_b
);

    reg [DATA_WIDTH-1:0] ram [0:RAM_DEPTH-1];
    reg [DATA_WIDTH-1:0] next_dout_a, next_dout_b;

    always @(*) begin
        if (rst) begin
            next_dout_a = 0;
            next_dout_b = 0;
        end else begin
            next_dout_a = ram[addr_a];
            next_dout_b = ram[addr_b];
        end
    end

    always @(posedge clk) begin
        if (rst) begin
            dout_a <= 0;
            dout_b <= 0;
        end else begin
            dout_a <= next_dout_a;
            dout_b <= next_dout_b;
            if (we_a) ram[addr_a] <= din_a;
            if (we_b) ram[addr_b] <= din_b;
        end
    end

endmodule
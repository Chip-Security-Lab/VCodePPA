module async_dual_port_ram #(
    parameter DATA_WIDTH = 8,
    parameter ADDR_WIDTH = 8
)(
    input wire [ADDR_WIDTH-1:0] addr_a, addr_b,
    input wire [DATA_WIDTH-1:0] din_a, din_b,
    output reg [DATA_WIDTH-1:0] dout_a, dout_b,
    input wire we_a, we_b
);

    reg [DATA_WIDTH-1:0] ram [(2**ADDR_WIDTH)-1:0];

    always @(addr_a or addr_b or we_a or we_b or din_a or din_b) begin
        if (we_a) ram[addr_a] = din_a;
        if (we_b) ram[addr_b] = din_b;
        dout_a = ram[addr_a];
        dout_b = ram[addr_b];
    end
endmodule

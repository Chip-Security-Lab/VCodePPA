module async_single_port_ram_with_output_enable #(
    parameter DATA_WIDTH = 8,
    parameter ADDR_WIDTH = 8
)(
    input wire [ADDR_WIDTH-1:0] addr,
    input wire [DATA_WIDTH-1:0] din,
    output reg [DATA_WIDTH-1:0] dout,
    input wire we,                 // 写使能
    input wire oe                  // 输出使能
);

    reg [DATA_WIDTH-1:0] ram [(2**ADDR_WIDTH)-1:0];

    always @* begin
        if (we) ram[addr] = din;  // 写数据
        if (oe) dout = ram[addr]; // 输出使能，才输出数据
    end
endmodule

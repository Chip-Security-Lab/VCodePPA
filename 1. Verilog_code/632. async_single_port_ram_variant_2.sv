//SystemVerilog
module async_single_port_ram #(
    parameter DATA_WIDTH = 8,
    parameter ADDR_WIDTH = 8
)(
    input wire [ADDR_WIDTH-1:0] addr,
    input wire [DATA_WIDTH-1:0] din,
    output reg [DATA_WIDTH-1:0] dout,
    input wire we
);

    reg [DATA_WIDTH-1:0] ram [(2**ADDR_WIDTH)-1:0];
    wire [DATA_WIDTH-1:0] write_data;
    wire [DATA_WIDTH-1:0] read_data;
    wire [DATA_WIDTH-1:0] din_comp;
    wire [DATA_WIDTH-1:0] ram_comp;
    wire [DATA_WIDTH-1:0] carry_in;
    wire [DATA_WIDTH-1:0] carry_out;

    // 补码转换
    assign din_comp = ~din + 1'b1;
    assign ram_comp = ~ram[addr] + 1'b1;

    // 补码加法实现减法
    assign {carry_out, write_data} = din_comp + ram_comp + carry_in;
    assign carry_in = 1'b0;

    always @(addr or we or din) begin
        if (we) begin
            ram[addr] = write_data;
        end
        dout = read_data;
    end

endmodule
module async_single_port_ram #(
    parameter DATA_WIDTH = 8,
    parameter ADDR_WIDTH = 8
)(
    input wire [ADDR_WIDTH-1:0] addr,
    input wire [DATA_WIDTH-1:0] din,
    output reg [DATA_WIDTH-1:0] dout,
    input wire we               // 写使能
);

    reg [DATA_WIDTH-1:0] ram [(2**ADDR_WIDTH)-1:0];

    always @(addr or we or din) begin
        if (we) begin
            ram[addr] = din;  // 写入数据
        end
        dout = ram[addr];   // 读取数据
    end
endmodule

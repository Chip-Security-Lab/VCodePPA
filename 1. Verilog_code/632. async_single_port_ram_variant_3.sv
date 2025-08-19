//SystemVerilog
module async_single_port_ram #(
    parameter DATA_WIDTH = 8,
    parameter ADDR_WIDTH = 8
)(
    input wire [ADDR_WIDTH-1:0] addr,
    input wire [DATA_WIDTH-1:0] din,
    output wire [DATA_WIDTH-1:0] dout,
    input wire we
);

    // 存储器阵列子模块
    ram_array #(
        .DATA_WIDTH(DATA_WIDTH),
        .ADDR_WIDTH(ADDR_WIDTH)
    ) ram_array_inst (
        .addr(addr),
        .din(din),
        .dout(dout),
        .we(we)
    );

endmodule

module ram_array #(
    parameter DATA_WIDTH = 8,
    parameter ADDR_WIDTH = 8
)(
    input wire [ADDR_WIDTH-1:0] addr,
    input wire [DATA_WIDTH-1:0] din,
    output reg [DATA_WIDTH-1:0] dout,
    input wire we
);

    reg [DATA_WIDTH-1:0] memory [(2**ADDR_WIDTH)-1:0];

    always @(addr or we or din) begin
        if (we) begin
            memory[addr] = din;
        end
        dout = memory[addr];
    end

endmodule
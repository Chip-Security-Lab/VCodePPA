//SystemVerilog
// 内存阵列子模块
module ram_array #(
    parameter DATA_WIDTH = 8,
    parameter ADDR_WIDTH = 8
)(
    input wire [ADDR_WIDTH-1:0] addr,
    input wire [DATA_WIDTH-1:0] din,
    output reg [DATA_WIDTH-1:0] dout,
    input wire we,
    input wire en
);

    reg [DATA_WIDTH-1:0] mem [(2**ADDR_WIDTH)-1:0];

    always @* begin
        if (en && we) mem[addr] = din;
        dout = mem[addr];
    end
endmodule

// 端口控制子模块
module port_controller #(
    parameter DATA_WIDTH = 8,
    parameter ADDR_WIDTH = 8
)(
    input wire [ADDR_WIDTH-1:0] addr,
    input wire [DATA_WIDTH-1:0] din,
    output wire [DATA_WIDTH-1:0] dout,
    input wire we,
    input wire en
);

    ram_array ram_inst (
        .addr(addr),
        .din(din),
        .dout(dout),
        .we(we),
        .en(en)
    );
endmodule

// 顶层双端口RAM模块
module async_dual_port_ram_with_enable #(
    parameter DATA_WIDTH = 8,
    parameter ADDR_WIDTH = 8
)(
    input wire [ADDR_WIDTH-1:0] addr_a, addr_b,
    input wire [DATA_WIDTH-1:0] din_a, din_b,
    output wire [DATA_WIDTH-1:0] dout_a, dout_b,
    input wire we_a, we_b,
    input wire en_a, en_b
);

    port_controller port_a (
        .addr(addr_a),
        .din(din_a),
        .dout(dout_a),
        .we(we_a),
        .en(en_a)
    );

    port_controller port_b (
        .addr(addr_b),
        .din(din_b),
        .dout(dout_b),
        .we(we_b),
        .en(en_b)
    );
endmodule
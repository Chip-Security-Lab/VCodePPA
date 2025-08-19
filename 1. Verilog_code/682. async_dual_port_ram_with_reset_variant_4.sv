//SystemVerilog
module async_dual_port_ram_with_reset #(
    parameter DATA_WIDTH = 8,
    parameter ADDR_WIDTH = 8
)(
    input wire [ADDR_WIDTH-1:0] addr_a, addr_b,
    input wire [DATA_WIDTH-1:0] din_a, din_b,
    output wire [DATA_WIDTH-1:0] dout_a, dout_b,
    input wire we_a, we_b,
    input wire rst
);

    // 内存阵列模块
    ram_array #(
        .DATA_WIDTH(DATA_WIDTH),
        .ADDR_WIDTH(ADDR_WIDTH)
    ) ram_array_inst (
        .addr_a(addr_a),
        .addr_b(addr_b),
        .din_a(din_a),
        .din_b(din_b),
        .dout_a(dout_a),
        .dout_b(dout_b),
        .we_a(we_a),
        .we_b(we_b),
        .rst(rst)
    );

endmodule

// 内存阵列子模块
module ram_array #(
    parameter DATA_WIDTH = 8,
    parameter ADDR_WIDTH = 8
)(
    input wire [ADDR_WIDTH-1:0] addr_a, addr_b,
    input wire [DATA_WIDTH-1:0] din_a, din_b,
    output reg [DATA_WIDTH-1:0] dout_a, dout_b,
    input wire we_a, we_b,
    input wire rst
);

    // 内存存储单元
    reg [DATA_WIDTH-1:0] mem [(2**ADDR_WIDTH)-1:0];

    // 写操作控制模块
    write_control #(
        .DATA_WIDTH(DATA_WIDTH),
        .ADDR_WIDTH(ADDR_WIDTH)
    ) write_control_inst (
        .addr_a(addr_a),
        .addr_b(addr_b),
        .din_a(din_a),
        .din_b(din_b),
        .we_a(we_a),
        .we_b(we_b),
        .rst(rst),
        .mem(mem)
    );

    // 读操作控制模块
    read_control #(
        .DATA_WIDTH(DATA_WIDTH),
        .ADDR_WIDTH(ADDR_WIDTH)
    ) read_control_inst (
        .addr_a(addr_a),
        .addr_b(addr_b),
        .dout_a(dout_a),
        .dout_b(dout_b),
        .rst(rst),
        .mem(mem)
    );

endmodule

// 写操作控制子模块
module write_control #(
    parameter DATA_WIDTH = 8,
    parameter ADDR_WIDTH = 8
)(
    input wire [ADDR_WIDTH-1:0] addr_a, addr_b,
    input wire [DATA_WIDTH-1:0] din_a, din_b,
    input wire we_a, we_b,
    input wire rst,
    output reg [DATA_WIDTH-1:0] mem [(2**ADDR_WIDTH)-1:0]
);

    always @* begin
        if (!rst) begin
            if (we_a) mem[addr_a] = din_a;
            if (we_b) mem[addr_b] = din_b;
        end
    end

endmodule

// 读操作控制子模块
module read_control #(
    parameter DATA_WIDTH = 8,
    parameter ADDR_WIDTH = 8
)(
    input wire [ADDR_WIDTH-1:0] addr_a, addr_b,
    output reg [DATA_WIDTH-1:0] dout_a, dout_b,
    input wire rst,
    input wire [DATA_WIDTH-1:0] mem [(2**ADDR_WIDTH)-1:0]
);

    always @* begin
        if (rst) begin
            dout_a = 0;
            dout_b = 0;
        end else begin
            dout_a = mem[addr_a];
            dout_b = mem[addr_b];
        end
    end

endmodule
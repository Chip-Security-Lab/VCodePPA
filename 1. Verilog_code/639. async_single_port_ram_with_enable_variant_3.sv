//SystemVerilog
// SystemVerilog
module async_single_port_ram_with_enable #(
    parameter DATA_WIDTH = 8,
    parameter ADDR_WIDTH = 8
)(
    input wire [ADDR_WIDTH-1:0] addr,
    input wire [DATA_WIDTH-1:0] din,
    output wire [DATA_WIDTH-1:0] dout,
    input wire we,
    input wire en
);

    // 实例化控制逻辑模块
    ram_control #(
        .DATA_WIDTH(DATA_WIDTH),
        .ADDR_WIDTH(ADDR_WIDTH)
    ) control_inst (
        .addr(addr),
        .din(din),
        .dout(dout),
        .we(we),
        .en(en),
        .mem_addr(addr),
        .mem_din(din),
        .mem_dout(mem_dout),
        .mem_we(mem_we)
    );

    // 实例化存储单元模块
    ram_memory #(
        .DATA_WIDTH(DATA_WIDTH),
        .ADDR_WIDTH(ADDR_WIDTH)
    ) memory_inst (
        .addr(mem_addr),
        .din(mem_din),
        .dout(mem_dout),
        .we(mem_we)
    );

    // 内部连接信号
    wire [ADDR_WIDTH-1:0] mem_addr;
    wire [DATA_WIDTH-1:0] mem_din;
    wire [DATA_WIDTH-1:0] mem_dout;
    wire mem_we;

endmodule

// 控制逻辑子模块
module ram_control #(
    parameter DATA_WIDTH = 8,
    parameter ADDR_WIDTH = 8
)(
    input wire [ADDR_WIDTH-1:0] addr,
    input wire [DATA_WIDTH-1:0] din,
    output reg [DATA_WIDTH-1:0] dout,
    input wire we,
    input wire en,
    output reg [ADDR_WIDTH-1:0] mem_addr,
    output reg [DATA_WIDTH-1:0] mem_din,
    input wire [DATA_WIDTH-1:0] mem_dout,
    output reg mem_we
);

    // 控制逻辑
    always @* begin
        if (en) begin
            mem_addr = addr;
            mem_din = din;
            mem_we = we;
            dout = mem_dout;
        end else begin
            mem_addr = addr;
            mem_din = din;
            mem_we = 1'b0;
            dout = {DATA_WIDTH{1'bz}}; // 高阻态
        end
    end

endmodule

// 存储单元子模块
module ram_memory #(
    parameter DATA_WIDTH = 8,
    parameter ADDR_WIDTH = 8
)(
    input wire [ADDR_WIDTH-1:0] addr,
    input wire [DATA_WIDTH-1:0] din,
    output reg [DATA_WIDTH-1:0] dout,
    input wire we
);

    reg [DATA_WIDTH-1:0] memory [(2**ADDR_WIDTH)-1:0];

    // 读写逻辑
    always @* begin
        if (we) begin
            memory[addr] = din;
        end
        dout = memory[addr];
    end

endmodule
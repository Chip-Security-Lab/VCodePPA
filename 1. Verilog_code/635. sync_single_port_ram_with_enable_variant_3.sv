//SystemVerilog
// 顶层模块
module sync_single_port_ram_with_enable #(
    parameter DATA_WIDTH = 8,
    parameter ADDR_WIDTH = 8
)(
    input wire clk,
    input wire rst,
    input wire en,
    input wire we,
    input wire [ADDR_WIDTH-1:0] addr,
    input wire [DATA_WIDTH-1:0] din,
    output wire [DATA_WIDTH-1:0] dout
);

    // 内部信号
    wire [ADDR_WIDTH-1:0] addr_reg;
    wire we_reg;
    wire [DATA_WIDTH-1:0] din_reg;

    // 实例化输入寄存器模块
    input_regs #(
        .DATA_WIDTH(DATA_WIDTH),
        .ADDR_WIDTH(ADDR_WIDTH)
    ) input_regs_inst (
        .clk(clk),
        .rst(rst),
        .en(en),
        .addr_in(addr),
        .we_in(we),
        .din_in(din),
        .addr_out(addr_reg),
        .we_out(we_reg),
        .din_out(din_reg)
    );

    // 实例化存储器核心模块
    ram_core #(
        .DATA_WIDTH(DATA_WIDTH),
        .ADDR_WIDTH(ADDR_WIDTH)
    ) ram_core_inst (
        .clk(clk),
        .rst(rst),
        .en(en),
        .we(we_reg),
        .addr(addr_reg),
        .din(din_reg),
        .dout(dout)
    );

endmodule

// 输入寄存器模块
module input_regs #(
    parameter DATA_WIDTH = 8,
    parameter ADDR_WIDTH = 8
)(
    input wire clk,
    input wire rst,
    input wire en,
    input wire [ADDR_WIDTH-1:0] addr_in,
    input wire we_in,
    input wire [DATA_WIDTH-1:0] din_in,
    output reg [ADDR_WIDTH-1:0] addr_out,
    output reg we_out,
    output reg [DATA_WIDTH-1:0] din_out
);

    // 地址寄存器逻辑
    always @(posedge clk or posedge rst) begin
        if (rst) begin
            addr_out <= 0;
        end else if (en) begin
            addr_out <= addr_in;
        end
    end
    
    // 写使能寄存器逻辑
    always @(posedge clk or posedge rst) begin
        if (rst) begin
            we_out <= 0;
        end else if (en) begin
            we_out <= we_in;
        end
    end
    
    // 输入数据寄存器逻辑
    always @(posedge clk or posedge rst) begin
        if (rst) begin
            din_out <= 0;
        end else if (en) begin
            din_out <= din_in;
        end
    end

endmodule

// 存储器核心模块
module ram_core #(
    parameter DATA_WIDTH = 8,
    parameter ADDR_WIDTH = 8
)(
    input wire clk,
    input wire rst,
    input wire en,
    input wire we,
    input wire [ADDR_WIDTH-1:0] addr,
    input wire [DATA_WIDTH-1:0] din,
    output reg [DATA_WIDTH-1:0] dout
);

    // 存储器数组
    reg [DATA_WIDTH-1:0] ram [(2**ADDR_WIDTH)-1:0];
    
    // 写操作逻辑
    always @(posedge clk) begin
        if (en && we) begin
            ram[addr] <= din;
        end
    end
    
    // 读操作逻辑
    always @(posedge clk or posedge rst) begin
        if (rst) begin
            dout <= 0;
        end else if (en) begin
            dout <= ram[addr];
        end
    end

endmodule
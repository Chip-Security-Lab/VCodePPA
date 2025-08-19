//SystemVerilog
// 顶层模块
module async_dram_ctrl #(
    parameter ADDR_WIDTH = 16,
    parameter DATA_WIDTH = 32
)(
    input wire clk,
    input wire we,
    input wire [ADDR_WIDTH-1:0] addr,
    input wire [DATA_WIDTH-1:0] wdata,
    output wire [DATA_WIDTH-1:0] rdata
);

    // 实例化内存阵列子模块
    dram_memory #(
        .ADDR_WIDTH(ADDR_WIDTH),
        .DATA_WIDTH(DATA_WIDTH)
    ) mem_inst (
        .clk(clk),
        .we(we),
        .addr(addr),
        .wdata(wdata),
        .rdata(rdata)
    );

endmodule

// 内存阵列子模块
module dram_memory #(
    parameter ADDR_WIDTH = 16,
    parameter DATA_WIDTH = 32
)(
    input wire clk,
    input wire we,
    input wire [ADDR_WIDTH-1:0] addr,
    input wire [DATA_WIDTH-1:0] wdata,
    output wire [DATA_WIDTH-1:0] rdata
);

    // 寄存器声明
    reg [DATA_WIDTH-1:0] memory [0:(1<<ADDR_WIDTH)-1];
    reg [DATA_WIDTH-1:0] rdata_reg;

    // 组合逻辑：地址解码
    wire [ADDR_WIDTH-1:0] addr_decoded;
    assign addr_decoded = addr;

    // 时序逻辑：写操作
    always @(posedge clk) begin
        if (we) begin
            memory[addr_decoded] <= wdata;
        end
    end

    // 时序逻辑：读操作
    always @(posedge clk) begin
        rdata_reg <= memory[addr_decoded];
    end

    // 组合逻辑：输出
    assign rdata = rdata_reg;

endmodule
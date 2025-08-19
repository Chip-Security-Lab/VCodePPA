//SystemVerilog
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

    // 寄存器声明
    reg [DATA_WIDTH-1:0] memory [0:(1<<ADDR_WIDTH)-1];
    reg [DATA_WIDTH-1:0] rdata_reg;
    reg [ADDR_WIDTH-1:0] addr_reg;
    reg [DATA_WIDTH-1:0] memory_read_data_reg;

    // 组合逻辑部分
    wire [DATA_WIDTH-1:0] memory_read_data;
    assign memory_read_data = memory[addr_reg];

    // 时序逻辑部分
    always @(posedge clk) begin
        // 地址寄存器
        addr_reg <= addr;
        
        // 写操作
        if (we) begin
            memory[addr] <= wdata;
        end
        
        // 读数据流水线寄存器
        memory_read_data_reg <= memory_read_data;
        
        // 输出寄存器
        rdata_reg <= memory_read_data_reg;
    end

    // 输出赋值
    assign rdata = rdata_reg;

endmodule
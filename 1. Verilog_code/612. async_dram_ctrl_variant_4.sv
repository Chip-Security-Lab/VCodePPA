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

    reg [DATA_WIDTH-1:0] memory [0:(1<<ADDR_WIDTH)-1];
    reg [DATA_WIDTH-1:0] rdata_reg;
    
    // 使用时钟控制的写逻辑
    always @(posedge clk) begin
        if (we)
            memory[addr] <= wdata;
        rdata_reg <= memory[addr];
    end

    assign rdata = rdata_reg;

endmodule
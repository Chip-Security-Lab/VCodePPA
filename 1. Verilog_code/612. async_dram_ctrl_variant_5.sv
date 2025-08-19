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
    reg [ADDR_WIDTH-1:0] addr_reg;
    reg we_reg;

    // Pipeline registers for timing optimization
    always @(posedge clk) begin
        addr_reg <= addr;
        we_reg <= we;
    end

    // Memory access with registered inputs
    always @(posedge clk) begin
        if (we_reg)
            memory[addr_reg] <= wdata;
        rdata_reg <= memory[addr_reg];
    end

    assign rdata = rdata_reg;

endmodule
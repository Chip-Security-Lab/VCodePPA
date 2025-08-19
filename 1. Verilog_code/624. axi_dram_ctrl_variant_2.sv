//SystemVerilog
module axi_dram_ctrl #(
    parameter ADDR_WIDTH = 32,
    parameter DATA_WIDTH = 64
)(
    input wire clk,
    input wire rst_n,
    input wire axi_awvalid,
    input wire axi_wvalid,
    input wire [ADDR_WIDTH-1:0] axi_awaddr,
    input wire [DATA_WIDTH-1:0] axi_wdata,
    output reg axi_bready,
    output reg [DATA_WIDTH-1:0] axi_rdata
);

    reg [DATA_WIDTH-1:0] memory [0:(1<<ADDR_WIDTH)-1];
    reg write_en;
    reg [ADDR_WIDTH-1:0] addr_reg;
    reg [DATA_WIDTH-1:0] wdata_reg;
    
    // 提前计算写使能信号
    always @(*) begin
        write_en = axi_awvalid && axi_wvalid;
    end
    
    // 地址和数据寄存器
    always @(posedge clk) begin
        addr_reg <= axi_awaddr;
        wdata_reg <= axi_wdata;
    end
    
    // 主状态机
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            axi_bready <= 0;
            axi_rdata <= 0;
        end else begin
            if (write_en) begin
                memory[addr_reg] <= wdata_reg;
                axi_bready <= 1;
            end else begin
                axi_rdata <= memory[addr_reg];
            end
        end
    end

endmodule
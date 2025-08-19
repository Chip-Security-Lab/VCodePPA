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

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            axi_bready <= 0;
            axi_rdata <= 0;
        end else if (axi_awvalid && axi_wvalid) begin
            memory[axi_awaddr] <= axi_wdata;
            axi_bready <= 1;
        end else begin
            axi_rdata <= memory[axi_awaddr];
        end
    end

endmodule

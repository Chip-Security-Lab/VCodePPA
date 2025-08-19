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

    wire write_en;
    wire [ADDR_WIDTH-1:0] write_addr;
    wire [DATA_WIDTH-1:0] write_data;
    wire [DATA_WIDTH-1:0] read_data;
    reg [DATA_WIDTH-1:0] read_data_stage1;

    write_control #(
        .ADDR_WIDTH(ADDR_WIDTH),
        .DATA_WIDTH(DATA_WIDTH)
    ) write_ctrl (
        .clk(clk),
        .rst_n(rst_n),
        .axi_awvalid(axi_awvalid),
        .axi_wvalid(axi_wvalid),
        .axi_awaddr(axi_awaddr),
        .axi_wdata(axi_wdata),
        .write_en(write_en),
        .axi_bready(axi_bready),
        .write_addr(write_addr),
        .write_data(write_data)
    );

    memory_array #(
        .ADDR_WIDTH(ADDR_WIDTH),
        .DATA_WIDTH(DATA_WIDTH)
    ) mem_array (
        .clk(clk),
        .rst_n(rst_n),
        .write_en(write_en),
        .addr(axi_awaddr),
        .write_data(write_data),
        .read_data(read_data)
    );

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            read_data_stage1 <= 0;
            axi_rdata <= 0;
        end else begin
            read_data_stage1 <= read_data;
            axi_rdata <= read_data_stage1;
        end
    end

endmodule

module memory_array #(
    parameter ADDR_WIDTH = 32,
    parameter DATA_WIDTH = 64
)(
    input wire clk,
    input wire rst_n,
    input wire write_en,
    input wire [ADDR_WIDTH-1:0] addr,
    input wire [DATA_WIDTH-1:0] write_data,
    output reg [DATA_WIDTH-1:0] read_data
);

    reg [DATA_WIDTH-1:0] memory [0:(1<<ADDR_WIDTH)-1];
    reg [ADDR_WIDTH-1:0] addr_stage1;
    reg write_en_stage1;
    reg [DATA_WIDTH-1:0] write_data_stage1;

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            addr_stage1 <= 0;
            write_en_stage1 <= 0;
            write_data_stage1 <= 0;
            read_data <= 0;
        end else begin
            addr_stage1 <= addr;
            write_en_stage1 <= write_en;
            write_data_stage1 <= write_data;
            read_data <= memory[addr_stage1];
            if (write_en_stage1) begin
                memory[addr_stage1] <= write_data_stage1;
            end
        end
    end

endmodule

module write_control #(
    parameter ADDR_WIDTH = 32,
    parameter DATA_WIDTH = 64
)(
    input wire clk,
    input wire rst_n,
    input wire axi_awvalid,
    input wire axi_wvalid,
    input wire [ADDR_WIDTH-1:0] axi_awaddr,
    input wire [DATA_WIDTH-1:0] axi_wdata,
    output reg write_en,
    output reg axi_bready,
    output reg [ADDR_WIDTH-1:0] write_addr,
    output reg [DATA_WIDTH-1:0] write_data
);

    reg axi_awvalid_stage1;
    reg axi_wvalid_stage1;
    reg [ADDR_WIDTH-1:0] axi_awaddr_stage1;
    reg [DATA_WIDTH-1:0] axi_wdata_stage1;

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            axi_awvalid_stage1 <= 0;
            axi_wvalid_stage1 <= 0;
            axi_awaddr_stage1 <= 0;
            axi_wdata_stage1 <= 0;
            write_en <= 0;
            axi_bready <= 0;
            write_addr <= 0;
            write_data <= 0;
        end else begin
            axi_awvalid_stage1 <= axi_awvalid;
            axi_wvalid_stage1 <= axi_wvalid;
            axi_awaddr_stage1 <= axi_awaddr;
            axi_wdata_stage1 <= axi_wdata;
            write_en <= axi_awvalid_stage1 && axi_wvalid_stage1;
            axi_bready <= axi_awvalid_stage1 && axi_wvalid_stage1;
            write_addr <= axi_awaddr_stage1;
            write_data <= axi_wdata_stage1;
        end
    end

endmodule
//SystemVerilog
module sync_single_port_ram_variable_depth #(
    parameter DATA_WIDTH = 8,
    parameter ADDR_WIDTH = 8,
    parameter RAM_DEPTH = 256
)(
    input wire clk,
    input wire rst,
    input wire we,
    input wire [ADDR_WIDTH-1:0] addr,
    input wire [DATA_WIDTH-1:0] din,
    output reg [DATA_WIDTH-1:0] dout
);

    reg [DATA_WIDTH-1:0] ram [0:RAM_DEPTH-1];
    reg [ADDR_WIDTH-1:0] addr_stage1;
    reg [DATA_WIDTH-1:0] din_stage1;
    reg we_stage1;
    reg [DATA_WIDTH-1:0] ram_out_stage1;
    reg [DATA_WIDTH-1:0] ram_out_stage2;

    // Address registration
    always @(posedge clk or posedge rst) begin
        if (rst)
            addr_stage1 <= 0;
        else
            addr_stage1 <= addr;
    end

    // Data input registration
    always @(posedge clk or posedge rst) begin
        if (rst)
            din_stage1 <= 0;
        else
            din_stage1 <= din;
    end

    // Write enable registration
    always @(posedge clk or posedge rst) begin
        if (rst)
            we_stage1 <= 0;
        else
            we_stage1 <= we;
    end

    // RAM write operation
    always @(posedge clk) begin
        if (we_stage1)
            ram[addr_stage1] <= din_stage1;
    end

    // RAM read operation - stage 1
    always @(posedge clk or posedge rst) begin
        if (rst)
            ram_out_stage1 <= 0;
        else
            ram_out_stage1 <= ram[addr_stage1];
    end

    // RAM read operation - stage 2
    always @(posedge clk or posedge rst) begin
        if (rst)
            ram_out_stage2 <= 0;
        else
            ram_out_stage2 <= ram_out_stage1;
    end

    // Output registration
    always @(posedge clk or posedge rst) begin
        if (rst)
            dout <= 0;
        else
            dout <= ram_out_stage2;
    end

endmodule
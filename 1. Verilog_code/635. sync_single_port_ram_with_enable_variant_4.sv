//SystemVerilog
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
    output reg [DATA_WIDTH-1:0] dout
);

    reg [DATA_WIDTH-1:0] ram [(2**ADDR_WIDTH)-1:0];
    reg [ADDR_WIDTH-1:0] addr_reg;
    reg en_reg;
    reg we_reg;
    reg [DATA_WIDTH-1:0] din_reg;
    reg [DATA_WIDTH-1:0] ram_data_reg;

    // Address pipeline
    always @(posedge clk or posedge rst) begin
        if (rst) addr_reg <= 0;
        else addr_reg <= addr;
    end

    // Enable pipeline
    always @(posedge clk or posedge rst) begin
        if (rst) en_reg <= 0;
        else en_reg <= en;
    end

    // Write enable pipeline
    always @(posedge clk or posedge rst) begin
        if (rst) we_reg <= 0;
        else we_reg <= we;
    end

    // Data input pipeline
    always @(posedge clk or posedge rst) begin
        if (rst) din_reg <= 0;
        else din_reg <= din;
    end

    // RAM write operation
    always @(posedge clk) begin
        if (en_reg && we_reg) begin
            ram[addr_reg] <= din_reg;
        end
    end

    // RAM read operation
    always @(posedge clk or posedge rst) begin
        if (rst) ram_data_reg <= 0;
        else if (en_reg) begin
            ram_data_reg <= ram[addr_reg];
        end
    end

    // Output pipeline
    always @(posedge clk or posedge rst) begin
        if (rst) dout <= 0;
        else dout <= ram_data_reg;
    end

endmodule
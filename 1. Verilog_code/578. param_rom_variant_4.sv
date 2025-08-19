//SystemVerilog
// ROM Memory Core Module
module rom_core #(
    parameter ADDR_WIDTH = 4,
    parameter DATA_WIDTH = 8
)(
    input [ADDR_WIDTH-1:0] addr,
    output [DATA_WIDTH-1:0] data_out
);
    reg [DATA_WIDTH-1:0] rom [0:(1<<ADDR_WIDTH)-1];

    initial begin
        rom[0] = 8'h12; rom[1] = 8'h34; rom[2] = 8'h56; rom[3] = 8'h78;
    end

    assign data_out = rom[addr];
endmodule

// Address Register Module
module addr_reg #(
    parameter ADDR_WIDTH = 4
)(
    input clk,
    input [ADDR_WIDTH-1:0] addr_in,
    output reg [ADDR_WIDTH-1:0] addr_out
);
    always @(posedge clk) begin
        addr_out <= addr_in;
    end
endmodule

// Data Register Module
module data_reg #(
    parameter DATA_WIDTH = 8
)(
    input clk,
    input [DATA_WIDTH-1:0] data_in,
    output reg [DATA_WIDTH-1:0] data_out
);
    always @(posedge clk) begin
        data_out <= data_in;
    end
endmodule

// Top Level ROM Module
module param_rom #(
    parameter ADDR_WIDTH = 4,
    parameter DATA_WIDTH = 8
)(
    input clk,
    input [ADDR_WIDTH-1:0] addr,
    output reg [DATA_WIDTH-1:0] data
);
    wire [ADDR_WIDTH-1:0] addr_reg_out;
    wire [DATA_WIDTH-1:0] rom_data;
    wire [DATA_WIDTH-1:0] data_reg_out;

    addr_reg #(
        .ADDR_WIDTH(ADDR_WIDTH)
    ) addr_reg_inst (
        .clk(clk),
        .addr_in(addr),
        .addr_out(addr_reg_out)
    );

    rom_core #(
        .ADDR_WIDTH(ADDR_WIDTH),
        .DATA_WIDTH(DATA_WIDTH)
    ) rom_core_inst (
        .addr(addr_reg_out),
        .data_out(rom_data)
    );

    data_reg #(
        .DATA_WIDTH(DATA_WIDTH)
    ) data_reg_inst (
        .clk(clk),
        .data_in(rom_data),
        .data_out(data_reg_out)
    );

    always @(posedge clk) begin
        data <= data_reg_out;
    end
endmodule
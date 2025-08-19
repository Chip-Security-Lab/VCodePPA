//SystemVerilog
module lfsr_core #(
    parameter WIDTH = 4,
    parameter TAPS = 4'b1100  // [3]^[2]
)(
    input clk,
    input rst,
    input [WIDTH-1:0] seed,
    output reg [WIDTH-1:0] lfsr_out
);

    always @(posedge clk or posedge rst) begin
        if (rst) begin
            lfsr_out <= seed;
        end else begin
            lfsr_out <= {lfsr_out[WIDTH-2:0], lfsr_out[WIDTH-1] ^ lfsr_out[WIDTH-2]};
        end
    end

endmodule

module rom_interface #(
    parameter ADDR_WIDTH = 4,
    parameter DATA_WIDTH = 8
)(
    input clk,
    input rst,
    input [ADDR_WIDTH-1:0] addr_in,
    input [DATA_WIDTH-1:0] rom_data,
    output reg [ADDR_WIDTH-1:0] addr_out,
    output reg [DATA_WIDTH-1:0] data_out
);

    always @(posedge clk or posedge rst) begin
        if (rst) begin
            addr_out <= {ADDR_WIDTH{1'b0}};
            data_out <= {DATA_WIDTH{1'b0}};
        end else begin
            addr_out <= addr_in;
            data_out <= rom_data;
        end
    end

endmodule

module lfsr_rom (
    input clk,
    input rst,
    output [3:0] addr,
    output [7:0] data
);

    reg [7:0] rom [0:15];
    wire [3:0] lfsr_addr;
    wire [3:0] rom_addr;
    wire [7:0] rom_data;

    initial begin
        rom[0] = 8'hA0; rom[1] = 8'hB1;
    end

    lfsr_core #(
        .WIDTH(4),
        .TAPS(4'b1100)
    ) lfsr_inst (
        .clk(clk),
        .rst(rst),
        .seed(4'b1010),
        .lfsr_out(lfsr_addr)
    );

    rom_interface #(
        .ADDR_WIDTH(4),
        .DATA_WIDTH(8)
    ) rom_inst (
        .clk(clk),
        .rst(rst),
        .addr_in(lfsr_addr),
        .rom_data(rom[rom_addr]),
        .addr_out(addr),
        .data_out(data)
    );

    assign rom_addr = lfsr_addr;

endmodule
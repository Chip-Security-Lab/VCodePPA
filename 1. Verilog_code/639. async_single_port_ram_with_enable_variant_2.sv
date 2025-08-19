//SystemVerilog
module lut_rom #(
    parameter DATA_WIDTH = 8,
    parameter ADDR_WIDTH = 8
)(
    input wire [ADDR_WIDTH-1:0] addr,
    output reg [DATA_WIDTH-1:0] dout
);

    reg [DATA_WIDTH-1:0] lut [0:255];
    
    initial begin
        for (integer i = 0; i < 256; i = i + 1) begin
            lut[i] = i;
        end
    end

    always @* begin
        dout = lut[addr];
    end

endmodule

module async_single_port_ram_with_enable #(
    parameter DATA_WIDTH = 8,
    parameter ADDR_WIDTH = 8
)(
    input wire [ADDR_WIDTH-1:0] addr,
    input wire [DATA_WIDTH-1:0] din,
    output reg [DATA_WIDTH-1:0] dout,
    input wire we,
    input wire en
);

    wire [DATA_WIDTH-1:0] lut_out;
    wire [ADDR_WIDTH-1:0] lut_addr;

    assign lut_addr = we ? din : addr;

    lut_rom #(
        .DATA_WIDTH(DATA_WIDTH),
        .ADDR_WIDTH(ADDR_WIDTH)
    ) lut_rom_inst (
        .addr(lut_addr),
        .dout(lut_out)
    );

    always @* begin
        if (en) begin
            dout = lut_out;
        end
    end

endmodule
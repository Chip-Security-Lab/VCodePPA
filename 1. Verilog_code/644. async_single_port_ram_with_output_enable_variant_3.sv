//SystemVerilog
// Memory Core Module
module memory_core #(
    parameter DATA_WIDTH = 8,
    parameter ADDR_WIDTH = 8
)(
    input wire [ADDR_WIDTH-1:0] addr,
    input wire [DATA_WIDTH-1:0] din,
    input wire we,
    output reg [DATA_WIDTH-1:0] dout
);

    reg [DATA_WIDTH-1:0] ram [(2**ADDR_WIDTH)-1:0];
    
    always @* begin
        if (we) begin
            ram[addr] = din;
        end
        dout = ram[addr];
    end
endmodule

// Output Control Module
module output_control #(
    parameter DATA_WIDTH = 8
)(
    input wire [DATA_WIDTH-1:0] data_in,
    input wire oe,
    output reg [DATA_WIDTH-1:0] data_out
);

    always @* begin
        if (oe) begin
            data_out = data_in;
        end else begin
            data_out = {DATA_WIDTH{1'bz}};
        end
    end
endmodule

// Input Register Module
module input_register #(
    parameter DATA_WIDTH = 8,
    parameter ADDR_WIDTH = 8
)(
    input wire [ADDR_WIDTH-1:0] addr_in,
    input wire [DATA_WIDTH-1:0] din_in,
    input wire we_in,
    input wire oe_in,
    output reg [ADDR_WIDTH-1:0] addr_out,
    output reg [DATA_WIDTH-1:0] din_out,
    output reg we_out,
    output reg oe_out
);

    always @* begin
        addr_out = addr_in;
        din_out = din_in;
        we_out = we_in;
        oe_out = oe_in;
    end
endmodule

// Top Level Module
module async_single_port_ram_with_output_enable #(
    parameter DATA_WIDTH = 8,
    parameter ADDR_WIDTH = 8
)(
    input wire [ADDR_WIDTH-1:0] addr,
    input wire [DATA_WIDTH-1:0] din,
    output wire [DATA_WIDTH-1:0] dout,
    input wire we,
    input wire oe
);

    wire [ADDR_WIDTH-1:0] addr_reg;
    wire [DATA_WIDTH-1:0] din_reg;
    wire we_reg;
    wire oe_reg;
    wire [DATA_WIDTH-1:0] mem_out;

    input_register #(
        .DATA_WIDTH(DATA_WIDTH),
        .ADDR_WIDTH(ADDR_WIDTH)
    ) input_reg_inst (
        .addr_in(addr),
        .din_in(din),
        .we_in(we),
        .oe_in(oe),
        .addr_out(addr_reg),
        .din_out(din_reg),
        .we_out(we_reg),
        .oe_out(oe_reg)
    );

    memory_core #(
        .DATA_WIDTH(DATA_WIDTH),
        .ADDR_WIDTH(ADDR_WIDTH)
    ) memory_inst (
        .addr(addr_reg),
        .din(din_reg),
        .we(we_reg),
        .dout(mem_out)
    );

    output_control #(
        .DATA_WIDTH(DATA_WIDTH)
    ) output_inst (
        .data_in(mem_out),
        .oe(oe_reg),
        .data_out(dout)
    );

endmodule
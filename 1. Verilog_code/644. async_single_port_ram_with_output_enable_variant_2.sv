//SystemVerilog
// Memory Core Module with Write First
module memory_core #(
    parameter DATA_WIDTH = 8,
    parameter ADDR_WIDTH = 8
)(
    input wire [ADDR_WIDTH-1:0] addr,
    input wire [DATA_WIDTH-1:0] din,
    output wire [DATA_WIDTH-1:0] dout,
    input wire we
);

    reg [DATA_WIDTH-1:0] ram [(2**ADDR_WIDTH)-1:0];
    reg [DATA_WIDTH-1:0] read_data;

    always @* begin
        if (we) begin
            ram[addr] = din;
            read_data = din;
        end else begin
            read_data = ram[addr];
        end
    end

    assign dout = read_data;
endmodule

// Output Control Module with Tri-State
module output_control #(
    parameter DATA_WIDTH = 8
)(
    input wire [DATA_WIDTH-1:0] data_in,
    output wire [DATA_WIDTH-1:0] data_out,
    input wire oe
);

    assign data_out = oe ? data_in : {DATA_WIDTH{1'bz}};
endmodule

// Address Decoder Module
module addr_decoder #(
    parameter ADDR_WIDTH = 8
)(
    input wire [ADDR_WIDTH-1:0] addr,
    output wire [ADDR_WIDTH-1:0] decoded_addr,
    input wire addr_valid
);

    assign decoded_addr = addr_valid ? addr : {ADDR_WIDTH{1'b0}};
endmodule

// Top Level RAM Module
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

    wire [ADDR_WIDTH-1:0] decoded_addr;
    wire [DATA_WIDTH-1:0] core_data_out;

    addr_decoder #(
        .ADDR_WIDTH(ADDR_WIDTH)
    ) addr_dec (
        .addr(addr),
        .decoded_addr(decoded_addr),
        .addr_valid(1'b1)
    );

    memory_core #(
        .DATA_WIDTH(DATA_WIDTH),
        .ADDR_WIDTH(ADDR_WIDTH)
    ) mem_core (
        .addr(decoded_addr),
        .din(din),
        .dout(core_data_out),
        .we(we)
    );

    output_control #(
        .DATA_WIDTH(DATA_WIDTH)
    ) out_ctrl (
        .data_in(core_data_out),
        .data_out(dout),
        .oe(oe)
    );
endmodule
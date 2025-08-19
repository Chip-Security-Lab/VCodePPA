//SystemVerilog
module sync_single_port_ram_with_bandwidth #(
    parameter DATA_WIDTH = 8,
    parameter ADDR_WIDTH = 8
)(
    input wire clk,
    input wire rst,
    input wire we,
    input wire [ADDR_WIDTH-1:0] addr,
    input wire [DATA_WIDTH-1:0] din,
    input wire bandwidth_control,
    output reg [DATA_WIDTH-1:0] dout
);

    reg [DATA_WIDTH-1:0] ram [(2**ADDR_WIDTH)-1:0];
    wire ram_access_enabled;
    wire [DATA_WIDTH-1:0] ram_data_out;
    reg [1:0] state;

    assign ram_access_enabled = ~rst & bandwidth_control;
    assign ram_data_out = ram[addr];

    always @(posedge clk) begin
        case ({rst, ram_access_enabled & we})
            2'b10: ram[addr] <= din;
            default: ram[addr] <= ram[addr];
        endcase
    end

    always @(posedge clk) begin
        case ({rst, ram_access_enabled})
            2'b10: dout <= ram_data_out;
            2'b01: dout <= ram_data_out;
            2'b11: dout <= ram_data_out;
            default: dout <= {DATA_WIDTH{1'b0}};
        endcase
    end

endmodule
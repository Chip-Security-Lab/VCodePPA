//SystemVerilog
module async_dual_port_ram_with_control #(
    parameter DATA_WIDTH = 8,
    parameter ADDR_WIDTH = 8
)(
    input wire [ADDR_WIDTH-1:0] addr_a, addr_b,
    input wire [DATA_WIDTH-1:0] din_a, din_b,
    output reg [DATA_WIDTH-1:0] dout_a, dout_b,
    input wire we_a, we_b,
    input wire control_signal_a, control_signal_b
);

    reg [DATA_WIDTH-1:0] ram [(2**ADDR_WIDTH)-1:0];
    wire write_enable_a, write_enable_b;

    assign write_enable_a = control_signal_a & we_a;
    assign write_enable_b = control_signal_b & we_b;

    always @* begin
        dout_a = ram[addr_a];
        dout_b = ram[addr_b];
        if (write_enable_a) begin
            ram[addr_a] = din_a;
            dout_a = din_a;
        end
        if (write_enable_b) begin
            ram[addr_b] = din_b;
            dout_b = din_b;
        end
    end
endmodule
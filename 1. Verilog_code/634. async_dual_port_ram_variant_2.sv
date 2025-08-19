//SystemVerilog
module ram_cell #(
    parameter DATA_WIDTH = 8
)(
    input wire [DATA_WIDTH-1:0] din,
    output reg [DATA_WIDTH-1:0] dout,
    input wire we
);
    reg [DATA_WIDTH-1:0] data;
    
    always @(*) begin
        if (we) data = din;
        dout = data;
    end
endmodule

module ram_array #(
    parameter DATA_WIDTH = 8,
    parameter ADDR_WIDTH = 8
)(
    input wire [ADDR_WIDTH-1:0] addr,
    input wire [DATA_WIDTH-1:0] din,
    output wire [DATA_WIDTH-1:0] dout,
    input wire we
);
    wire [DATA_WIDTH-1:0] cell_dout [(2**ADDR_WIDTH)-1:0];
    wire [DATA_WIDTH-1:0] cell_din [(2**ADDR_WIDTH)-1:0];
    wire [2**ADDR_WIDTH-1:0] cell_we;
    
    genvar i;
    generate
        for (i = 0; i < 2**ADDR_WIDTH; i = i + 1) begin : ram_cells
            assign cell_din[i] = din;
            assign cell_we[i] = we & (addr == i);
            ram_cell #(DATA_WIDTH) cell_inst (
                .din(cell_din[i]),
                .dout(cell_dout[i]),
                .we(cell_we[i])
            );
        end
    endgenerate
    
    assign dout = cell_dout[addr];
endmodule

module async_dual_port_ram #(
    parameter DATA_WIDTH = 8,
    parameter ADDR_WIDTH = 8
)(
    input wire [ADDR_WIDTH-1:0] addr_a, addr_b,
    input wire [DATA_WIDTH-1:0] din_a, din_b,
    output wire [DATA_WIDTH-1:0] dout_a, dout_b,
    input wire we_a, we_b
);
    ram_array #(DATA_WIDTH, ADDR_WIDTH) port_a (
        .addr(addr_a),
        .din(din_a),
        .dout(dout_a),
        .we(we_a)
    );
    
    ram_array #(DATA_WIDTH, ADDR_WIDTH) port_b (
        .addr(addr_b),
        .din(din_b),
        .dout(dout_b),
        .we(we_b)
    );
endmodule
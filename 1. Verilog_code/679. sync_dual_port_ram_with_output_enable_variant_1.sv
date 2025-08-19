//SystemVerilog
module sync_dual_port_ram_with_output_enable #(
    parameter DATA_WIDTH = 8,
    parameter ADDR_WIDTH = 8
)(
    input wire clk,
    input wire rst,
    input wire we_a, we_b,
    input wire oe_a, oe_b,
    input wire [ADDR_WIDTH-1:0] addr_a, addr_b,
    input wire [DATA_WIDTH-1:0] din_a, din_b,
    output reg [DATA_WIDTH-1:0] dout_a, dout_b
);

    wire [DATA_WIDTH-1:0] ram_dout_a, ram_dout_b;
    wire [DATA_WIDTH-1:0] dout_a_int, dout_b_int;

    ram_array #(
        .DATA_WIDTH(DATA_WIDTH),
        .ADDR_WIDTH(ADDR_WIDTH)
    ) u_ram_array (
        .clk(clk),
        .we_a(we_a),
        .we_b(we_b),
        .addr_a(addr_a),
        .addr_b(addr_b),
        .din_a(din_a),
        .din_b(din_b),
        .dout_a(ram_dout_a),
        .dout_b(ram_dout_b)
    );

    output_control #(
        .DATA_WIDTH(DATA_WIDTH)
    ) u_output_control (
        .clk(clk),
        .rst(rst),
        .oe_a(oe_a),
        .oe_b(oe_b),
        .dout_a(ram_dout_a),
        .dout_b(ram_dout_b),
        .dout_a_reg(dout_a_int),
        .dout_b_reg(dout_b_int)
    );

    always @(posedge clk) begin
        dout_a <= dout_a_int;
        dout_b <= dout_b_int;
    end

endmodule

module ram_array #(
    parameter DATA_WIDTH = 8,
    parameter ADDR_WIDTH = 8
)(
    input wire clk,
    input wire we_a, we_b,
    input wire [ADDR_WIDTH-1:0] addr_a, addr_b,
    input wire [DATA_WIDTH-1:0] din_a, din_b,
    output reg [DATA_WIDTH-1:0] dout_a, dout_b
);

    reg [DATA_WIDTH-1:0] ram [(2**ADDR_WIDTH)-1:0];
    reg [ADDR_WIDTH-1:0] addr_a_reg, addr_b_reg;
    reg [DATA_WIDTH-1:0] din_a_reg, din_b_reg;
    reg we_a_reg, we_b_reg;

    always @(posedge clk) begin
        addr_a_reg <= addr_a;
        addr_b_reg <= addr_b;
        din_a_reg <= din_a;
        din_b_reg <= din_b;
        we_a_reg <= we_a;
        we_b_reg <= we_b;
    end

    always @(posedge clk) begin
        if (we_a_reg) ram[addr_a_reg] <= din_a_reg;
        if (we_b_reg) ram[addr_b_reg] <= din_b_reg;
        dout_a <= ram[addr_a_reg];
        dout_b <= ram[addr_b_reg];
    end

endmodule

module output_control #(
    parameter DATA_WIDTH = 8
)(
    input wire clk,
    input wire rst,
    input wire oe_a, oe_b,
    input wire [DATA_WIDTH-1:0] dout_a, dout_b,
    output reg [DATA_WIDTH-1:0] dout_a_reg, dout_b_reg
);

    reg oe_a_reg, oe_b_reg;
    reg [DATA_WIDTH-1:0] dout_a_pipe, dout_b_pipe;

    always @(posedge clk or posedge rst) begin
        if (rst) begin
            oe_a_reg <= 0;
            oe_b_reg <= 0;
            dout_a_pipe <= 0;
            dout_b_pipe <= 0;
        end else begin
            oe_a_reg <= oe_a;
            oe_b_reg <= oe_b;
            dout_a_pipe <= dout_a;
            dout_b_pipe <= dout_b;
        end
    end

    always @(posedge clk) begin
        if (oe_a_reg) dout_a_reg <= dout_a_pipe;
        if (oe_b_reg) dout_b_reg <= dout_b_pipe;
    end

endmodule
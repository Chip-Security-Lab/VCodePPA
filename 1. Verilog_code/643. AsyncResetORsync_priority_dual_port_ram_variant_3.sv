//SystemVerilog
module ram_core #(
    parameter DATA_WIDTH = 8,
    parameter ADDR_WIDTH = 8
)(
    input wire clk,
    input wire rst,
    input wire we_a, we_b,
    input wire [ADDR_WIDTH-1:0] addr_a, addr_b,
    input wire [DATA_WIDTH-1:0] din_a, din_b,
    output reg [DATA_WIDTH-1:0] dout_a, dout_b
);

    reg [DATA_WIDTH-1:0] ram [(2**ADDR_WIDTH)-1:0];
    
    always @(posedge clk) begin
        if (we_a) ram[addr_a] <= din_a;
        if (we_b) ram[addr_b] <= din_b;
    end
    
    always @(posedge clk or posedge rst) begin
        if (rst) begin
            dout_a <= 0;
            dout_b <= 0;
        end else begin
            dout_a <= ram[addr_a];
            dout_b <= ram[addr_b];
        end
    end
endmodule

module priority_controller #(
    parameter DATA_WIDTH = 8
)(
    input wire clk,
    input wire rst,
    input wire read_first,
    input wire [DATA_WIDTH-1:0] dout_a_in, dout_b_in,
    output reg [DATA_WIDTH-1:0] dout_a, dout_b
);

    always @(posedge clk or posedge rst) begin
        if (rst) begin
            dout_a <= 0;
            dout_b <= 0;
        end else begin
            if (read_first) begin
                dout_a <= dout_a_in;
                dout_b <= dout_b_in;
            end else begin
                dout_a <= dout_a_in;
                dout_b <= dout_b_in;
            end
        end
    end
endmodule

module sync_priority_dual_port_ram #(
    parameter DATA_WIDTH = 8,
    parameter ADDR_WIDTH = 8
)(
    input wire clk,
    input wire rst,
    input wire we_a, we_b,
    input wire read_first,
    input wire [ADDR_WIDTH-1:0] addr_a, addr_b,
    input wire [DATA_WIDTH-1:0] din_a, din_b,
    output wire [DATA_WIDTH-1:0] dout_a, dout_b
);

    wire [DATA_WIDTH-1:0] ram_dout_a, ram_dout_b;
    
    ram_core #(
        .DATA_WIDTH(DATA_WIDTH),
        .ADDR_WIDTH(ADDR_WIDTH)
    ) ram_inst (
        .clk(clk),
        .rst(rst),
        .we_a(we_a),
        .we_b(we_b),
        .addr_a(addr_a),
        .addr_b(addr_b),
        .din_a(din_a),
        .din_b(din_b),
        .dout_a(ram_dout_a),
        .dout_b(ram_dout_b)
    );
    
    priority_controller #(
        .DATA_WIDTH(DATA_WIDTH)
    ) priority_inst (
        .clk(clk),
        .rst(rst),
        .read_first(read_first),
        .dout_a_in(ram_dout_a),
        .dout_b_in(ram_dout_b),
        .dout_a(dout_a),
        .dout_b(dout_b)
    );
endmodule
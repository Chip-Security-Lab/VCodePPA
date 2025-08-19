//SystemVerilog
module cond_inv_subtractor #(
    parameter WIDTH = 32
)(
    input [WIDTH-1:0] a,
    input [WIDTH-1:0] b,
    output [WIDTH-1:0] diff,
    output borrow
);

    wire [WIDTH-1:0] b_inv;
    wire [WIDTH:0] carry;
    wire [WIDTH-1:0] sum;
    
    assign b_inv = ~b;
    assign carry[0] = 1'b1;
    
    genvar i;
    generate
        for (i = 0; i < WIDTH; i = i + 1) begin : sub_loop
            assign {carry[i+1], sum[i]} = a[i] + b_inv[i] + carry[i];
        end
    endgenerate
    
    assign diff = sum;
    assign borrow = ~carry[WIDTH];

endmodule

module tdp_ram_core #(
    parameter DATA_WIDTH = 32,
    parameter BYTE_SIZE = 8,
    parameter ADDR_WIDTH = 10
)(
    input clk,
    input [ADDR_WIDTH-1:0] addr,
    input [DATA_WIDTH-1:0] din,
    output reg [DATA_WIDTH-1:0] dout,
    input [DATA_WIDTH/BYTE_SIZE-1:0] we
);

    localparam BYTE_NUM = DATA_WIDTH/BYTE_SIZE;
    reg [DATA_WIDTH-1:0] mem [0:(1<<ADDR_WIDTH)-1];
    integer i;

    always @(posedge clk) begin
        dout <= mem[addr];
        for (i=0; i<BYTE_NUM; i=i+1) begin
            if (we[i]) begin
                mem[addr][i*BYTE_SIZE +: BYTE_SIZE] <= din[i*BYTE_SIZE +: BYTE_SIZE];
            end
        end
    end

endmodule

module tdp_ram_byte_en #(
    parameter DATA_WIDTH = 32,
    parameter BYTE_SIZE = 8,
    parameter ADDR_WIDTH = 10
)(
    input clk,
    // Port X
    input [ADDR_WIDTH-1:0] x_addr,
    input [DATA_WIDTH-1:0] x_din,
    output [DATA_WIDTH-1:0] x_dout,
    input [DATA_WIDTH/BYTE_SIZE-1:0] x_we,
    // Port Y
    input [ADDR_WIDTH-1:0] y_addr,
    input [DATA_WIDTH-1:0] y_din,
    output [DATA_WIDTH-1:0] y_dout,
    input [DATA_WIDTH/BYTE_SIZE-1:0] y_we,
    // Subtractor interface
    input [DATA_WIDTH-1:0] sub_a,
    input [DATA_WIDTH-1:0] sub_b,
    output [DATA_WIDTH-1:0] sub_diff,
    output sub_borrow
);

    // Instantiate memory core for Port X
    tdp_ram_core #(
        .DATA_WIDTH(DATA_WIDTH),
        .BYTE_SIZE(BYTE_SIZE),
        .ADDR_WIDTH(ADDR_WIDTH)
    ) port_x (
        .clk(clk),
        .addr(x_addr),
        .din(x_din),
        .dout(x_dout),
        .we(x_we)
    );

    // Instantiate memory core for Port Y
    tdp_ram_core #(
        .DATA_WIDTH(DATA_WIDTH),
        .BYTE_SIZE(BYTE_SIZE),
        .ADDR_WIDTH(ADDR_WIDTH)
    ) port_y (
        .clk(clk),
        .addr(y_addr),
        .din(y_din),
        .dout(y_dout),
        .we(y_we)
    );

    // Instantiate conditional inverse subtractor
    cond_inv_subtractor #(
        .WIDTH(DATA_WIDTH)
    ) subtractor (
        .a(sub_a),
        .b(sub_b),
        .diff(sub_diff),
        .borrow(sub_borrow)
    );

endmodule
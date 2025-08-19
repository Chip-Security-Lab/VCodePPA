//SystemVerilog
module sync_dual_port_ram_with_clock_sync #(
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

    // 实例化内存阵列模块
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
        .dout_a(dout_a),
        .dout_b(dout_b)
    );

endmodule

// 内存阵列子模块
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
    wire [DATA_WIDTH-1:0] sub_result_a, sub_result_b;
    wire borrow_a, borrow_b;

    // 实例化先行借位减法器
    carry_lookahead_subtractor #(
        .WIDTH(DATA_WIDTH)
    ) u_sub_a (
        .a(din_a),
        .b(ram[addr_a]),
        .result(sub_result_a),
        .borrow(borrow_a)
    );

    carry_lookahead_subtractor #(
        .WIDTH(DATA_WIDTH)
    ) u_sub_b (
        .a(din_b),
        .b(ram[addr_b]),
        .result(sub_result_b),
        .borrow(borrow_b)
    );

    always @(posedge clk) begin
        if (we_a) ram[addr_a] <= sub_result_a;
        if (we_b) ram[addr_b] <= sub_result_b;
        dout_a <= ram[addr_a];
        dout_b <= ram[addr_b];
    end

endmodule

// 先行借位减法器模块
module carry_lookahead_subtractor #(
    parameter WIDTH = 8
)(
    input wire [WIDTH-1:0] a,
    input wire [WIDTH-1:0] b,
    output wire [WIDTH-1:0] result,
    output wire borrow
);

    wire [WIDTH:0] borrow_out;
    wire [WIDTH-1:0] b_not;
    wire [WIDTH-1:0] p, g;

    assign b_not = ~b;
    assign borrow_out[0] = 1'b1;

    genvar i;
    generate
        for(i = 0; i < WIDTH; i = i + 1) begin : gen_sub
            assign p[i] = a[i] ^ b_not[i];
            assign g[i] = a[i] & b_not[i];
            assign borrow_out[i+1] = g[i] | (p[i] & borrow_out[i]);
            assign result[i] = p[i] ^ borrow_out[i];
        end
    endgenerate

    assign borrow = borrow_out[WIDTH];

endmodule

// 时钟域同步子模块
module clock_sync #(
    parameter DATA_WIDTH = 8
)(
    input wire clk,
    input wire rst,
    input wire [DATA_WIDTH-1:0] din,
    output reg [DATA_WIDTH-1:0] dout
);

    always @(posedge clk or posedge rst) begin
        if (rst) dout <= 0;
        else dout <= din;
    end

endmodule
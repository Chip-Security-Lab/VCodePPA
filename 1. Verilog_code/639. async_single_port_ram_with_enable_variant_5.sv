//SystemVerilog
module conditional_inversion_subtractor #(
    parameter DATA_WIDTH = 8
)(
    input wire [DATA_WIDTH-1:0] a,
    input wire [DATA_WIDTH-1:0] b,
    output wire [DATA_WIDTH-1:0] diff,
    output wire borrow
);

    wire [DATA_WIDTH-1:0] b_inv;
    wire [DATA_WIDTH-1:0] sum;
    wire [DATA_WIDTH-1:0] carry;
    wire [DATA_WIDTH-1:0] final_carry;

    // 反相减数
    assign b_inv = ~b;

    // 半加器实现
    genvar i;
    generate
        for (i = 0; i < DATA_WIDTH; i = i + 1) begin : half_adder
            assign sum[i] = a[i] ^ b_inv[i];
            assign carry[i] = a[i] & b_inv[i];
        end
    endgenerate

    // 进位传播逻辑
    assign final_carry[0] = carry[0];
    genvar j;
    generate
        for (j = 1; j < DATA_WIDTH; j = j + 1) begin : carry_propagation
            assign final_carry[j] = carry[j] | (sum[j] & final_carry[j-1]);
        end
    endgenerate

    // 结果计算
    assign diff = sum ^ {final_carry[DATA_WIDTH-2:0], 1'b0};
    assign borrow = final_carry[DATA_WIDTH-1];

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

    reg [DATA_WIDTH-1:0] ram [(2**ADDR_WIDTH)-1:0];

    // 写操作
    always @* begin
        if (en && we) begin
            ram[addr] = din;
        end
    end

    // 读操作
    always @* begin
        if (en) begin
            dout = ram[addr];
        end
    end

endmodule

module ram_with_subtraction #(
    parameter DATA_WIDTH = 8,
    parameter ADDR_WIDTH = 8
)(
    input wire [ADDR_WIDTH-1:0] addr,
    input wire [DATA_WIDTH-1:0] din,
    input wire [DATA_WIDTH-1:0] subtrahend,
    output wire [DATA_WIDTH-1:0] dout,
    output wire [DATA_WIDTH-1:0] diff,
    output wire borrow,
    input wire we,
    input wire en
);

    wire [DATA_WIDTH-1:0] ram_out;

    async_single_port_ram_with_enable #(
        .DATA_WIDTH(DATA_WIDTH),
        .ADDR_WIDTH(ADDR_WIDTH)
    ) ram_inst (
        .addr(addr),
        .din(din),
        .dout(ram_out),
        .we(we),
        .en(en)
    );

    conditional_inversion_subtractor #(
        .DATA_WIDTH(DATA_WIDTH)
    ) subtractor_inst (
        .a(ram_out),
        .b(subtrahend),
        .diff(diff),
        .borrow(borrow)
    );

    assign dout = ram_out;

endmodule
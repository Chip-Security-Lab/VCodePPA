//SystemVerilog
module sync_dual_port_ram_with_reset_enable #(
    parameter DATA_WIDTH = 8,
    parameter ADDR_WIDTH = 8
)(
    input wire clk,
    input wire rst, 
    input wire en,
    input wire we_a, we_b,
    input wire [ADDR_WIDTH-1:0] addr_a, addr_b,
    input wire [DATA_WIDTH-1:0] din_a, din_b,
    output reg [DATA_WIDTH-1:0] dout_a, dout_b
);

    // ... existing code ...

    // 实例化借位减法器模块
    borrow_subtractor #(
        .WIDTH(DATA_WIDTH)
    ) sub_unit (
        .a(din_a),
        .b(din_b),
        .diff(diff_out),
        .borrow(borrow_out)
    );

    // ... existing code ...

endmodule

module borrow_subtractor #(
    parameter WIDTH = 8
)(
    input wire [WIDTH-1:0] a,
    input wire [WIDTH-1:0] b,
    output reg [WIDTH-1:0] diff,
    output reg borrow
);

    reg [WIDTH:0] borrow_chain;
    integer i;

    always @(*) begin
        borrow_chain[0] = 1'b0;
        for (i = 0; i < WIDTH; i = i + 1) begin
            diff[i] = a[i] ^ b[i] ^ borrow_chain[i];
            borrow_chain[i+1] = (~a[i] & b[i]) | ((~a[i] | b[i]) & borrow_chain[i]);
        end
        borrow = borrow_chain[WIDTH];
    end

endmodule

// ... existing code ...
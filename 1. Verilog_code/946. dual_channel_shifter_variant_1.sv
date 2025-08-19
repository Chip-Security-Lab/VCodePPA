//SystemVerilog
module dual_channel_shifter (
    input clk,
    input [15:0] ch1, ch2,
    input [3:0] shift,
    output reg [15:0] out1, out2
);
    // 临时信号用于借位减法器结果
    wire [15:0] neg_shift;
    wire borrow;
    
    // 使用借位减法器算法计算(16-shift)
    borrow_subtractor #(
        .WIDTH(16)
    ) sub_inst (
        .a(16'd16),
        .b({12'b0, shift}),
        .diff(neg_shift),
        .borrow_out(borrow)
    );
    
    always @(posedge clk) begin
        out1 <= (ch1 << shift) | (ch1 >> neg_shift);
        out2 <= (ch2 >> shift) | (ch2 << neg_shift);
    end
endmodule

module borrow_subtractor #(
    parameter WIDTH = 16
)(
    input [WIDTH-1:0] a,
    input [WIDTH-1:0] b,
    output [WIDTH-1:0] diff,
    output borrow_out
);
    wire [WIDTH:0] borrow;
    
    assign borrow[0] = 1'b0;
    
    generate
        genvar i;
        for (i = 0; i < WIDTH; i = i + 1) begin: sub_loop
            assign diff[i] = a[i] ^ b[i] ^ borrow[i];
            assign borrow[i+1] = (~a[i] & b[i]) | (~a[i] & borrow[i]) | (b[i] & borrow[i]);
        end
    endgenerate
    
    assign borrow_out = borrow[WIDTH];
endmodule
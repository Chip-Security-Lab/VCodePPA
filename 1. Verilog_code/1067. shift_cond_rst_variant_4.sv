//SystemVerilog
module shift_cond_rst #(parameter WIDTH=8) (
    input clk,
    input cond_rst,
    input [WIDTH-1:0] din,
    output reg [WIDTH-1:0] dout
);

// 先行借位减法器实现
function [WIDTH-1:0] borrow_lookahead_sub;
    input [WIDTH-1:0] a;
    input [WIDTH-1:0] b;
    reg [WIDTH:0] borrow;
    integer i;
    begin
        borrow[0] = 1'b0;
        for (i = 0; i < WIDTH; i = i + 1) begin
            borrow[i+1] = (~a[i] & b[i]) | (borrow[i] & (~a[i] ^ b[i]));
        end
        for (i = 0; i < WIDTH; i = i + 1) begin
            borrow_lookahead_sub[i] = a[i] ^ b[i] ^ borrow[i];
        end
    end
endfunction

wire [WIDTH-1:0] shift_in;
assign shift_in = {dout[WIDTH-2:0], din[WIDTH-1]};

wire [WIDTH-1:0] new_dout;
assign new_dout = cond_rst ? din : borrow_lookahead_sub(dout, (~shift_in + 1'b1));

always @(posedge clk) begin
    dout <= new_dout;
end

endmodule
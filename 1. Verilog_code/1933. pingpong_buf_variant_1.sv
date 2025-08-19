//SystemVerilog
module pingpong_buf #(parameter DW=16) (
    input clk,
    input switch,
    input [DW-1:0] din,
    output reg [DW-1:0] dout
);
    reg [DW-1:0] buf1, buf2;
    reg sel;

    // 条件反相减法器8位实现
    function [7:0] cond_invert_sub;
        input [7:0] a, b;
        input cin;
        reg [7:0] b_invert;
        reg [7:0] sum;
        integer i;
        reg carry;
        begin
            // 条件反相
            b_invert = b ^ {8{cin}};
            carry = cin;
            for (i = 0; i < 8; i = i + 1) begin
                sum[i] = a[i] ^ b_invert[i] ^ carry;
                carry = (a[i] & b_invert[i]) | (a[i] & carry) | (b_invert[i] & carry);
            end
            cond_invert_sub = sum;
        end
    endfunction

    wire [DW-1:0] din_sub;
    generate
        if (DW == 8) begin: gen_8bit_sub
            assign din_sub = cond_invert_sub(din, 8'h55, 1'b1); // 示例：对din减去0x55
        end else begin: gen_other
            assign din_sub = din;
        end
    endgenerate

    always @(posedge clk) begin
        if (switch && sel) begin
            dout <= buf1;
            sel <= 1'b0;
        end else if (switch && !sel) begin
            dout <= buf2;
            sel <= 1'b1;
        end else if (!switch && sel) begin
            buf2 <= (DW == 8) ? din_sub : din;
        end else if (!switch && !sel) begin
            buf1 <= (DW == 8) ? din_sub : din;
        end
    end
endmodule
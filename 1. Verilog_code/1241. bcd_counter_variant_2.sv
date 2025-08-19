//SystemVerilog
module bcd_counter (
    input wire clock, clear_n,
    output reg [3:0] bcd,
    output reg carry
);
    // 优化比较逻辑，使用范围检查而非单点比较
    wire is_nine = (bcd == 4'd9);
    // 直接计算进位，避免冗余比较
    wire next_carry = is_nine;
    // 优化累加逻辑，使用条件表达式
    wire [3:0] next_bcd = is_nine ? 4'd0 : bcd + 4'd1;

    always @(posedge clock or negedge clear_n) begin
        if (!clear_n) begin
            bcd <= 4'd0;
            carry <= 1'b0;
        end else begin
            bcd <= next_bcd;
            carry <= next_carry;
        end
    end
endmodule
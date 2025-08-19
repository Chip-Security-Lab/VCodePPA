module BCDSub(
    input [7:0] bcd_a,
    input [7:0] bcd_b,
    output reg [7:0] bcd_res
);

    wire [7:0] bcd_b_comp;
    wire [7:0] sum;
    wire carry;
    
    // 计算B的补码
    assign bcd_b_comp = ~bcd_b + 1'b1;
    
    // 条件求和减法
    assign {carry, sum} = bcd_a + bcd_b_comp;
    
    // 根据进位选择结果
    always @(*) begin
        if (carry) begin
            bcd_res = sum;
        end else begin
            bcd_res = sum - 8'h6;
        end
    end

endmodule
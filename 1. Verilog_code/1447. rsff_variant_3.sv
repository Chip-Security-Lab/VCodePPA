//SystemVerilog
module rsff (
    input  wire clk, set, reset,
    output reg  q
);
    // 优化比较逻辑，使用case语句根据{set,reset}位组合进行判断
    // 这种方式可以更清晰地表达状态转换并减少比较链的复杂度
    always @(posedge clk) begin
        case ({set, reset})
            2'b10:   q <= 1'b1;  // 只有set有效
            2'b01:   q <= 1'b0;  // 只有reset有效
            2'b11:   q <= 1'bx;  // set和reset同时有效，不确定状态
            default: q <= q;     // 保持当前状态
        endcase
    end
endmodule
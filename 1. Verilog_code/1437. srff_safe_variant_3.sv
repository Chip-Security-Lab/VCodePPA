//SystemVerilog
module srff_safe (
    input clk, s, r,
    output reg q
);
    
    // 组合s和r作为case的条件变量
    reg [1:0] sr;
    
    always @(posedge clk) begin
        sr = {s, r};  // 构建2位控制信号
        
        case(sr)
            2'b11: q <= 1'bx; // 非法状态处理
            2'b10: q <= 1'b1; // 置位
            2'b01: q <= 1'b0; // 复位
            2'b00: q <= q;    // 保持当前状态
        endcase
    end
endmodule
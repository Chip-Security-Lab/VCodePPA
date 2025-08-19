//SystemVerilog
module jkff #(parameter W=1) (
    input clk, rstn,
    input [W-1:0] j, k,
    output reg [W-1:0] q
);
    // 预计算下一状态逻辑，减少关键路径长度
    reg [W-1:0] next_q;
    
    always @(*) begin
        for (integer i = 0; i < W; i = i + 1) begin
            case ({j[i], k[i]})
                2'b00: next_q[i] = q[i];     // 保持状态
                2'b01: next_q[i] = 1'b0;     // 复位
                2'b10: next_q[i] = 1'b1;     // 置位
                2'b11: next_q[i] = ~q[i];    // 翻转
            endcase
        end
    end
    
    // 寄存器更新逻辑
    always @(posedge clk or negedge rstn) begin
        if (!rstn) begin
            q <= {W{1'b0}};
        end else begin
            q <= next_q;
        end
    end
endmodule
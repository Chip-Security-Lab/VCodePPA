//SystemVerilog
module tff_clear (
    input  logic clk,
    input  logic clr,
    output logic q
);
    // 简化流水线结构和控制信号
    logic toggle_next;
    logic [1:0] valid_sr;
    
    // 合并第一级流水线决策逻辑
    always_ff @(posedge clk) begin
        if (clr) begin
            toggle_next <= 1'b0;
            valid_sr <= 2'b00;
        end
        else begin
            // 直接计算下一个状态
            toggle_next <= ~q;
            // 移位寄存器实现延迟计数
            valid_sr <= {valid_sr[0], 1'b1};
        end
    end
    
    // 简化输出寄存器逻辑
    always_ff @(posedge clk) begin
        if (clr) begin
            q <= 1'b0;
        end
        else if (valid_sr[1]) begin
            q <= toggle_next;
        end
    end
endmodule
//SystemVerilog
module shift_ff (
    input clk, rstn, 
    input sin,
    output reg q
);

    // 中间流水线寄存器
    reg sin_stage1;
    reg sin_stage2;
    
    // 增加流水线深度，将单级操作分为三级
    always @(posedge clk) begin
        if (!rstn) begin
            sin_stage1 <= 1'b0;
            sin_stage2 <= 1'b0;
            q <= 1'b0;
        end else begin
            sin_stage1 <= sin;        // 第一级流水线
            sin_stage2 <= sin_stage1; // 第二级流水线
            q <= sin_stage2;          // 第三级流水线
        end
    end

endmodule
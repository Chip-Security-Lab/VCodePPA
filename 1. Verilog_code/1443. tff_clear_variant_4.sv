//SystemVerilog
module tff_clear (
    input wire clk,
    input wire clr,
    input wire valid_in,  // 输入有效信号
    output wire valid_out, // 输出有效信号
    output wire q
);

    // 内部信号和寄存器
    wire next_state;
    reg q_reg;
    reg valid_reg;
    
    // 计算下一状态 - 移动到组合逻辑部分
    assign next_state = ~q_reg;
    
    // 统一的寄存器级 - 将原本靠近输出的寄存器移至组合逻辑之前
    always @(posedge clk) begin
        if (clr) begin
            q_reg <= 1'b0;
            valid_reg <= 1'b0;
        end else begin
            if (valid_in) begin
                q_reg <= next_state;
                valid_reg <= valid_in;
            end else begin
                valid_reg <= 1'b0;
            end
        end
    end

    // 直接输出寄存器值 - 减少输出路径延迟
    assign q = q_reg;
    assign valid_out = valid_reg;

endmodule
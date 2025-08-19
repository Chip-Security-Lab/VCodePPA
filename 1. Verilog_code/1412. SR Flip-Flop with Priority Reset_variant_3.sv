//SystemVerilog
module sr_ff_priority_reset (
    input  wire clk,
    input  wire s,
    input  wire r,
    input  wire valid_in,   // 输入有效信号
    output wire valid_out,  // 输出有效信号
    output wire q
);
    // 第一级流水线寄存器
    reg s_stage1, r_stage1;
    reg valid_stage1;
    
    // 第二级流水线寄存器
    reg next_q_stage2;
    reg valid_stage2;
    
    // 输出寄存器
    reg q_reg;
    reg valid_reg;
    
    // 第一级流水线 - s信号寄存
    always @(posedge clk) begin
        s_stage1 <= s;
    end
    
    // 第一级流水线 - r信号寄存
    always @(posedge clk) begin
        r_stage1 <= r;
    end
    
    // 第一级流水线 - valid信号寄存
    always @(posedge clk) begin
        valid_stage1 <= valid_in;
    end
    
    // 第二级流水线 - 优先级复位逻辑计算
    always @(posedge clk) begin
        if (r_stage1)
            next_q_stage2 <= 1'b0;  // Reset has priority
        else if (s_stage1)
            next_q_stage2 <= 1'b1;  // Set
        else
            next_q_stage2 <= q_reg; // No change
    end
    
    // 第二级流水线 - valid信号传递
    always @(posedge clk) begin
        valid_stage2 <= valid_stage1;
    end
    
    // 第三级流水线 - q输出寄存
    always @(posedge clk) begin
        q_reg <= next_q_stage2;
    end
    
    // 第三级流水线 - valid输出寄存
    always @(posedge clk) begin
        valid_reg <= valid_stage2;
    end
    
    // 输出赋值
    assign q = q_reg;
    assign valid_out = valid_reg;
    
endmodule
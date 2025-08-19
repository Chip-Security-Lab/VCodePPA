//SystemVerilog
module pulse_sync #(
    parameter DST_CLK_RATIO = 2
)(
    input src_clk,
    input dst_clk,
    input src_rst_n,
    input dst_rst_n,
    input src_pulse,
    input src_valid,
    output src_ready,
    output dst_pulse,
    output dst_valid,
    input dst_ready
);

// 源时钟域流水线寄存器 - 增加流水线深度
reg src_flag;
reg src_valid_stage1, src_valid_stage2, src_valid_stage3, src_valid_stage4;
reg src_pulse_stage1, src_pulse_stage2, src_pulse_stage3, src_pulse_stage4;
reg src_handshake_stage1, src_handshake_stage2;

// 目标时钟域流水线寄存器 - 增加流水线深度
reg [4:0] sync_chain;  // 增加同步链长度
reg dst_flag;
reg dst_pulse_stage1, dst_pulse_stage2, dst_pulse_stage3, dst_pulse_stage4;
reg dst_valid_stage1, dst_valid_stage2, dst_valid_stage3, dst_valid_stage4;
reg dst_handshake_stage1, dst_handshake_stage2;

// 流水线控制信号
wire src_handshake;
wire dst_handshake;

assign src_handshake = src_valid & src_ready;
assign dst_handshake = dst_valid & dst_ready;
assign src_ready = 1'b1;  // 简化版本，总是准备好接收新脉冲

// 源时钟域流水线 - 拆分为更多级
always @(posedge src_clk or negedge src_rst_n) begin
    if (!src_rst_n) begin
        src_flag <= 1'b0;
        src_valid_stage1 <= 1'b0;
        src_valid_stage2 <= 1'b0;
        src_valid_stage3 <= 1'b0;
        src_valid_stage4 <= 1'b0;
        src_pulse_stage1 <= 1'b0;
        src_pulse_stage2 <= 1'b0;
        src_pulse_stage3 <= 1'b0;
        src_pulse_stage4 <= 1'b0;
        src_handshake_stage1 <= 1'b0;
        src_handshake_stage2 <= 1'b0;
    end else begin
        // 第一级流水线 - 输入寄存
        if (src_handshake) begin
            src_pulse_stage1 <= src_pulse;
            src_valid_stage1 <= src_valid;
        end
        src_handshake_stage1 <= src_handshake;
        
        // 第二级流水线
        src_pulse_stage2 <= src_pulse_stage1;
        src_valid_stage2 <= src_valid_stage1;
        src_handshake_stage2 <= src_handshake_stage1;
        
        // 第三级流水线
        src_pulse_stage3 <= src_pulse_stage2;
        src_valid_stage3 <= src_valid_stage2;
        
        // 第四级流水线
        src_pulse_stage4 <= src_pulse_stage3;
        src_valid_stage4 <= src_valid_stage3;
        
        // 只在有效脉冲时才翻转标志 - 最后一级
        if (src_valid_stage4 && src_pulse_stage4) begin
            src_flag <= ~src_flag;
        end
    end
end

// 目标时钟域流水线 - 拆分同步链和脉冲检测为更多级
always @(posedge dst_clk or negedge dst_rst_n) begin
    if (!dst_rst_n) begin
        sync_chain <= 5'b00000;
        dst_flag <= 1'b0;
        dst_pulse_stage1 <= 1'b0;
        dst_pulse_stage2 <= 1'b0;
        dst_pulse_stage3 <= 1'b0;
        dst_pulse_stage4 <= 1'b0;
        dst_valid_stage1 <= 1'b0;
        dst_valid_stage2 <= 1'b0;
        dst_valid_stage3 <= 1'b0;
        dst_valid_stage4 <= 1'b0;
        dst_handshake_stage1 <= 1'b0;
        dst_handshake_stage2 <= 1'b0;
    end else begin
        // 同步链 - 第一级流水线 - 增加同步器长度提高MTBF
        sync_chain <= {sync_chain[3:0], src_flag};
        dst_handshake_stage1 <= dst_handshake;
        
        // 第二级流水线 - 同步数据寄存
        dst_handshake_stage2 <= dst_handshake_stage1;
        
        // 第三级流水线 - 脉冲检测第一阶段
        dst_pulse_stage1 <= (sync_chain[4] ^ dst_flag);
        dst_valid_stage1 <= 1'b1;  // 一旦同步链稳定，数据总是有效的
        
        // 第四级流水线 - 脉冲检测第二阶段
        dst_pulse_stage2 <= dst_pulse_stage1;
        dst_valid_stage2 <= dst_valid_stage1;
        
        // 第五级流水线 - 输出寄存第一阶段
        dst_pulse_stage3 <= dst_pulse_stage2;
        dst_valid_stage3 <= dst_valid_stage2;
        
        // 第六级流水线 - 输出寄存第二阶段
        dst_pulse_stage4 <= dst_pulse_stage3;
        dst_valid_stage4 <= dst_valid_stage3;
        
        // 更新目标标志寄存器，用于下一次脉冲检测
        if (dst_handshake) begin
            dst_flag <= sync_chain[4];
        end
    end
end

// 输出赋值
assign dst_pulse = dst_pulse_stage4;
assign dst_valid = dst_valid_stage4;

endmodule
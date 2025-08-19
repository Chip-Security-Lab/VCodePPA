//SystemVerilog
module preset_ring_counter(
    input wire clk,
    input wire rst,
    input wire preset,
    input wire valid_in,
    output wire valid_out,
    output reg [3:0] q
);
    // 增加流水线级数，将原来的3级流水线改为5级
    reg [3:0] q_stage1, q_stage2, q_stage3, q_stage4;
    reg valid_stage1, valid_stage2, valid_stage3, valid_stage4;
    reg preset_stage1, preset_stage2, preset_stage3, preset_stage4;
    
    // 第一级流水线 - 输入处理
    always @(posedge clk) begin
        if (rst) begin
            q_stage1 <= 4'b0001;
            valid_stage1 <= 1'b0;
            preset_stage1 <= 1'b0;
        end
        else begin
            valid_stage1 <= valid_in;
            preset_stage1 <= preset;
            if (preset)
                q_stage1 <= 4'b1000; // 预设值
            else if (valid_in)
                q_stage1 <= {q[2:0], q[3]}; // 基于当前输出计算下一状态
            else
                q_stage1 <= q_stage1; // 保持当前值
        end
    end
    
    // 第二级流水线 - 预处理阶段
    always @(posedge clk) begin
        if (rst) begin
            q_stage2 <= 4'b0000;
            valid_stage2 <= 1'b0;
            preset_stage2 <= 1'b0;
        end
        else begin
            q_stage2 <= q_stage1;
            valid_stage2 <= valid_stage1;
            preset_stage2 <= preset_stage1;
        end
    end
    
    // 第三级流水线 - 中间处理阶段1
    always @(posedge clk) begin
        if (rst) begin
            q_stage3 <= 4'b0000;
            valid_stage3 <= 1'b0;
            preset_stage3 <= 1'b0;
        end
        else begin
            q_stage3 <= q_stage2;
            valid_stage3 <= valid_stage2;
            preset_stage3 <= preset_stage2;
        end
    end
    
    // 第四级流水线 - 中间处理阶段2
    always @(posedge clk) begin
        if (rst) begin
            q_stage4 <= 4'b0000;
            valid_stage4 <= 1'b0;
            preset_stage4 <= 1'b0;
        end
        else begin
            q_stage4 <= q_stage3;
            valid_stage4 <= valid_stage3;
            preset_stage4 <= preset_stage3;
        end
    end
    
    // 第五级流水线 - 输出阶段
    always @(posedge clk) begin
        if (rst) begin
            q <= 4'b0001;
        end
        else if (valid_stage4) begin
            if (preset_stage4)
                q <= 4'b1000; // 确保预设值在输出阶段也被处理
            else
                q <= q_stage4; // 更新输出
        end
    end
    
    // 输出有效信号
    assign valid_out = valid_stage4;
    
endmodule
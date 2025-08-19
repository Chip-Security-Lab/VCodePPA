//SystemVerilog
module d_ff_sync_preset (
    input wire clk,
    input wire preset,
    input wire d,
    input wire valid_in,
    output wire valid_out,
    output reg q
);
    // 流水线寄存器 - 增加到4级流水线
    reg d_stage1, d_stage2, d_stage3, d_stage4;
    reg preset_stage1, preset_stage2, preset_stage3, preset_stage4;
    reg valid_stage1, valid_stage2, valid_stage3, valid_stage4;
    
    // 第一级流水线
    always @(posedge clk) begin
        d_stage1 <= d;
        preset_stage1 <= preset;
        valid_stage1 <= valid_in;
    end
    
    // 第二级流水线
    always @(posedge clk) begin
        d_stage2 <= d_stage1;
        preset_stage2 <= preset_stage1;
        valid_stage2 <= valid_stage1;
    end
    
    // 第三级流水线 (新增)
    always @(posedge clk) begin
        d_stage3 <= d_stage2;
        preset_stage3 <= preset_stage2;
        valid_stage3 <= valid_stage2;
    end
    
    // 第四级流水线 (新增)
    always @(posedge clk) begin
        d_stage4 <= d_stage3;
        preset_stage4 <= preset_stage3;
        valid_stage4 <= valid_stage3;
    end
    
    // 输出级流水线
    always @(posedge clk) begin
        if (valid_stage4) begin
            if (preset_stage4)
                q <= 1'b1;
            else
                q <= d_stage4;
        end
    end
    
    // 输出有效信号
    assign valid_out = valid_stage4;
    
endmodule
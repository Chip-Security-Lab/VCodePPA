//SystemVerilog
module ps2_codec (
    input clk_ps2, data,
    output reg [7:0] keycode,
    output reg parity_ok
);
    // 增加流水线级数，将原有两级流水线扩展为四级
    
    // 第一级：数据采样
    reg data_stage1;
    
    // 第二级：移位寄存器操作
    reg [10:0] shift_stage2;
    reg data_stage2;
    
    // 第三级：奇偶校验和键码提取
    reg shift_complete_stage3;
    reg [7:0] keycode_stage3;
    reg parity_calc_stage3;
    
    // 第四级：输出寄存器
    reg [7:0] keycode_stage4;
    reg parity_ok_stage4;

    // 第一级流水线：采样输入数据
    always @(negedge clk_ps2) begin
        data_stage1 <= data;
    end
    
    // 第二级流水线 - 第一部分：更新前级数据
    always @(negedge clk_ps2) begin
        data_stage2 <= data_stage1;
    end
    
    // 第二级流水线 - 第二部分：数据移位操作
    always @(negedge clk_ps2) begin
        shift_stage2 <= {data_stage2, shift_stage2[10:1]};
    end
    
    // 第三级流水线 - 第一部分：完成标志处理
    always @(posedge clk_ps2) begin
        shift_complete_stage3 <= shift_stage2[0];
    end
    
    // 第三级流水线 - 第二部分：键码提取和校验
    always @(posedge clk_ps2) begin
        if (shift_stage2[0]) begin
            keycode_stage3 <= shift_stage2[8:1];
            parity_calc_stage3 <= (^shift_stage2[8:1]) == shift_stage2[9];
        end
    end
    
    // 第四级流水线 - 第一部分：内部寄存器更新
    always @(posedge clk_ps2) begin
        if (shift_complete_stage3) begin
            keycode_stage4 <= keycode_stage3;
            parity_ok_stage4 <= parity_calc_stage3;
        end
    end
    
    // 第四级流水线 - 第二部分：输出寄存器更新
    always @(posedge clk_ps2) begin
        if (shift_complete_stage3) begin
            keycode <= keycode_stage3;
            parity_ok <= parity_calc_stage3;
        end
    end
endmodule
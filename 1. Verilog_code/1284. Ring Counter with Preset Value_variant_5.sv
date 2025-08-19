//SystemVerilog
module preset_ring_counter(
    input wire clk,
    input wire rst,
    input wire preset,
    output reg [3:0] q
);
    // 增加流水线阶段寄存器
    reg [3:0] q_stage1;
    reg [3:0] q_stage2;
    
    // 流水线控制信号
    reg rst_stage1, rst_stage2;
    reg preset_stage1, preset_stage2;
    
    // 第一级流水线 - 寄存控制信号并计算下一个状态
    always @(posedge clk) begin
        rst_stage1 <= rst;
        preset_stage1 <= preset;
        
        case ({rst, preset})
            2'b10, 2'b11: q_stage1 <= 4'b0001; // Reset has highest priority
            2'b01:        q_stage1 <= 4'b1000; // Preset condition
            default:      q_stage1 <= {q[2:0], q[3]}; // Normal ring counter operation
        endcase
    end
    
    // 第二级流水线 - 中间处理阶段
    always @(posedge clk) begin
        rst_stage2 <= rst_stage1;
        preset_stage2 <= preset_stage1;
        q_stage2 <= q_stage1;
    end
    
    // 第三级流水线 - 输出阶段
    always @(posedge clk) begin
        // 最终数据输出，保持优先级处理
        case ({rst_stage2, preset_stage2})
            2'b10, 2'b11: q <= 4'b0001; // Reset still has highest priority
            2'b01:        q <= 4'b1000; // Preset condition
            default:      q <= q_stage2; // Pass through processed data
        endcase
    end
endmodule
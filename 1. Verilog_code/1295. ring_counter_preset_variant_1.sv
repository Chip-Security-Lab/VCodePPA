//SystemVerilog
module ring_counter_preset (
    input wire clk,
    input wire load,
    input wire [3:0] preset_val,
    output reg [3:0] out
);
    // 增加流水线寄存器
    reg load_stage1, load_stage2;
    reg [3:0] preset_val_stage1, preset_val_stage2;
    reg [3:0] intermediate_stage1, intermediate_stage2;
    
    // 第一级流水线 - 捕获输入信号
    always @(posedge clk) begin
        load_stage1 <= load;
        preset_val_stage1 <= preset_val;
        intermediate_stage1 <= {out[0], out[3:1]};
    end
    
    // 第二级流水线 - 处理中间结果
    always @(posedge clk) begin
        load_stage2 <= load_stage1;
        preset_val_stage2 <= preset_val_stage1;
        intermediate_stage2 <= intermediate_stage1;
    end
    
    // 最终输出级 - 生成结果
    always @(posedge clk) begin
        out <= load_stage2 ? preset_val_stage2 : intermediate_stage2;
    end
endmodule
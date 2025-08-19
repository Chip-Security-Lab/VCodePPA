//SystemVerilog
// IEEE 1364-2005 Verilog标准
module trigger_shadow_reg #(
    parameter WIDTH = 16
)(
    input wire clock,
    input wire nreset,
    input wire [WIDTH-1:0] data_in,
    input wire [WIDTH-1:0] trigger_value,
    output reg [WIDTH-1:0] shadow_data,
    // 流水线控制信号
    input wire valid_in,
    output wire valid_out,
    input wire ready_in,
    output wire ready_out
);
    // 三阶段流水线寄存器
    reg [WIDTH-1:0] stage1_data;
    reg [WIDTH-1:0] stage2_data;
    reg [WIDTH-1:0] stage3_data;
    
    // 流水线控制信号
    reg stage1_valid, stage2_valid, stage3_valid;
    
    // 比较结果流水线寄存器
    reg stage2_match;
    reg stage3_match;
    
    // 流水线就绪信号
    assign ready_out = ready_in || !stage1_valid;
    assign valid_out = stage3_valid;
    
    // 合并所有时钟域同步逻辑
    always @(posedge clock or negedge nreset) begin
        if (~nreset) begin
            // 第一阶段复位
            stage1_data <= {WIDTH{1'b0}};
            stage1_valid <= 1'b0;
            
            // 第二阶段复位
            stage2_data <= {WIDTH{1'b0}};
            stage2_valid <= 1'b0;
            stage2_match <= 1'b0;
            
            // 第三阶段复位
            stage3_data <= {WIDTH{1'b0}};
            stage3_valid <= 1'b0;
            stage3_match <= 1'b0;
            
            // 输出寄存器复位
            shadow_data <= {WIDTH{1'b0}};
        end
        else begin
            // 第一阶段: 数据寄存
            if (ready_out) begin
                stage1_data <= data_in;
                stage1_valid <= valid_in;
            end
            
            // 第二阶段: 比较处理
            if (ready_in || !stage2_valid) begin
                stage2_data <= stage1_data;
                stage2_valid <= stage1_valid;
                stage2_match <= (stage1_data == trigger_value) && stage1_valid;
            end
            
            // 第三阶段: 触发捕获
            if (ready_in || !stage3_valid) begin
                stage3_data <= stage2_data;
                stage3_valid <= stage2_valid;
                stage3_match <= stage2_match;
            end
            
            // 最终输出处理
            if (stage3_match) begin
                shadow_data <= stage3_data;
            end
        end
    end
endmodule
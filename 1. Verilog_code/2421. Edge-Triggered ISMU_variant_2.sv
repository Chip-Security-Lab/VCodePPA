//SystemVerilog
/* IEEE 1364-2005 */
module edge_triggered_ismu #(parameter SRC_COUNT = 8)(
    input wire clk, rst_n,
    input wire [SRC_COUNT-1:0] intr_sources,
    input wire [SRC_COUNT-1:0] intr_mask,
    output reg [SRC_COUNT-1:0] pending_intr,
    output wire intr_valid
);
    // 第一级流水线寄存器 - 输入捕获
    reg [SRC_COUNT-1:0] intr_sources_stage1;
    reg [SRC_COUNT-1:0] intr_mask_stage1;
    reg [SRC_COUNT-1:0] intr_sources_r;
    reg valid_stage1;
    
    // 第二级流水线寄存器 - 中间结果
    reg [SRC_COUNT-1:0] edge_detected_stage2;
    reg valid_stage2;
    
    // 第三级流水线寄存器 - 输出准备
    reg [SRC_COUNT-1:0] pending_update_stage3;
    reg valid_stage3;
    
    // 组合逻辑 - 第一级：边沿检测计算
    wire [SRC_COUNT-1:0] edge_detected_comb;
    assign edge_detected_comb = (~intr_mask_stage1) & intr_sources_stage1 & (~intr_sources_r);
    
    // 输出逻辑
    assign intr_valid = |pending_intr;
    
    // 第一级流水线 - 输入捕获
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            intr_sources_stage1 <= {SRC_COUNT{1'b0}};
            intr_mask_stage1 <= {SRC_COUNT{1'b0}};
            intr_sources_r <= {SRC_COUNT{1'b0}};
            valid_stage1 <= 1'b0;
        end else begin
            intr_sources_stage1 <= intr_sources;
            intr_mask_stage1 <= intr_mask;
            intr_sources_r <= intr_sources;
            valid_stage1 <= 1'b1;
        end
    end
    
    // 第二级流水线 - 边沿检测处理
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            edge_detected_stage2 <= {SRC_COUNT{1'b0}};
            valid_stage2 <= 1'b0;
        end else begin
            edge_detected_stage2 <= edge_detected_comb;
            valid_stage2 <= valid_stage1;
        end
    end
    
    // 第三级流水线 - 准备更新pending_intr
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            pending_update_stage3 <= {SRC_COUNT{1'b0}};
            valid_stage3 <= 1'b0;
        end else begin
            pending_update_stage3 <= edge_detected_stage2;
            valid_stage3 <= valid_stage2;
        end
    end
    
    // 最终输出阶段 - 更新pending_intr
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            pending_intr <= {SRC_COUNT{1'b0}};
        end else if (valid_stage3) begin
            // 累积已检测到的边沿触发中断
            pending_intr <= pending_intr | pending_update_stage3;
        end
    end
endmodule
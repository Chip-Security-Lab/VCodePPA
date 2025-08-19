//SystemVerilog
module edge_triggered_ismu #(parameter SRC_COUNT = 8)(
    input wire clk, rst_n,
    input wire [SRC_COUNT-1:0] intr_sources,
    input wire [SRC_COUNT-1:0] intr_mask,
    output reg [SRC_COUNT-1:0] pending_intr,
    output wire intr_valid
);
    reg [SRC_COUNT-1:0] intr_sources_r;
    reg [SRC_COUNT-1:0] rising_edge;
    reg [SRC_COUNT-1:0] masked_intr;
    reg [SRC_COUNT-1:0] edge_detected;
    
    // 中断有效信号计算
    assign intr_valid = |pending_intr;
    
    // 多级条件逻辑，引入中间变量
    always @(*) begin
        // 第一级：检测上升沿
        rising_edge = intr_sources & (~intr_sources_r);
        
        // 第二级：应用掩码
        masked_intr = ~intr_mask;
        
        // 第三级：最终检测逻辑
        edge_detected = rising_edge & masked_intr;
    end
    
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            // 复位逻辑
            intr_sources_r <= {SRC_COUNT{1'b0}};
            pending_intr <= {SRC_COUNT{1'b0}};
        end 
        else begin
            // 正常操作逻辑
            intr_sources_r <= intr_sources;
            
            // 分开判断中断累积逻辑
            if (|edge_detected) begin
                // 有新的中断被检测到
                pending_intr <= pending_intr | edge_detected;
            end
            // 无新中断时保持当前状态
        end
    end
endmodule
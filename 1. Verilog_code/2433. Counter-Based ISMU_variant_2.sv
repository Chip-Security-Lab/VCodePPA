//SystemVerilog
module counter_ismu #(parameter N = 8)(
    input wire CLK, nRST,
    input wire [N-1:0] IRQ,
    input wire CLR_CNT,
    output reg [N-1:0] IRQ_STATUS,
    output reg [N-1:0][7:0] IRQ_COUNT
);
    // 第一级流水线：边沿检测阶段
    reg [N-1:0] IRQ_stage1, IRQ_stage2;
    reg [N-1:0] edge_detect_stage1;
    reg valid_stage1;
    reg CLR_CNT_stage1;
    
    // 第二级流水线：计数控制阶段
    reg [N-1:0] edge_detect_stage2;
    reg valid_stage2;
    reg CLR_CNT_stage2;
    reg [N-1:0] count_en;
    reg [N-1:0] status_set;
    
    // 计数逻辑优化
    reg [N-1:0] count_overflow; // 标记计数器是否已满
    
    // 第一级流水线 - 边沿检测
    always @(posedge CLK or negedge nRST) begin
        if (!nRST) begin
            IRQ_stage1 <= {N{1'b0}};
            IRQ_stage2 <= {N{1'b0}};
            edge_detect_stage1 <= {N{1'b0}};
            valid_stage1 <= 1'b0;
            CLR_CNT_stage1 <= 1'b0;
        end else begin
            IRQ_stage1 <= IRQ;
            IRQ_stage2 <= IRQ_stage1;
            edge_detect_stage1 <= IRQ_stage1 & ~IRQ_stage2; // 上升沿检测
            valid_stage1 <= 1'b1;
            CLR_CNT_stage1 <= CLR_CNT;
        end
    end
    
    // 预计算计数器溢出状态来平衡关键路径
    always @(posedge CLK or negedge nRST) begin
        if (!nRST) begin
            count_overflow <= {N{1'b0}};
        end else begin
            for (int i = 0; i < N; i = i + 1) begin
                count_overflow[i] <= (IRQ_COUNT[i] == 8'hFF);
            end
        end
    end
    
    // 第二级流水线 - 计数控制 - 优化逻辑路径
    always @(posedge CLK or negedge nRST) begin
        if (!nRST) begin
            edge_detect_stage2 <= {N{1'b0}};
            valid_stage2 <= 1'b0;
            CLR_CNT_stage2 <= 1'b0;
            count_en <= {N{1'b0}};
            status_set <= {N{1'b0}};
        end else begin
            edge_detect_stage2 <= edge_detect_stage1;
            valid_stage2 <= valid_stage1;
            CLR_CNT_stage2 <= CLR_CNT_stage1;
            
            if (valid_stage1) begin
                for (int i = 0; i < N; i = i + 1) begin
                    // 优化决策逻辑，使用预计算的溢出标志
                    count_en[i] <= edge_detect_stage1[i] & ~count_overflow[i];
                    status_set[i] <= edge_detect_stage1[i];
                end
            end else begin
                count_en <= {N{1'b0}};
                status_set <= {N{1'b0}};
            end
        end
    end
    
    // 第三级流水线 - 计数与状态更新 - 拆分大循环减少关键路径
    // 分离清除逻辑和计数更新逻辑
    reg CLR_active;
    reg [N-1:0] final_count_en;
    reg [N-1:0] final_status_set;
    
    always @(posedge CLK or negedge nRST) begin
        if (!nRST) begin
            CLR_active <= 1'b0;
            final_count_en <= {N{1'b0}};
            final_status_set <= {N{1'b0}};
        end else begin
            CLR_active <= CLR_CNT_stage2 & valid_stage2;
            final_count_en <= count_en & {N{valid_stage2}} & ~{N{CLR_CNT_stage2}};
            final_status_set <= status_set & {N{valid_stage2}} & ~{N{CLR_CNT_stage2}};
        end
    end
    
    // 更新计数器和状态寄存器
    always @(posedge CLK or negedge nRST) begin
        if (!nRST) begin
            IRQ_COUNT <= {N{8'h0}};
            IRQ_STATUS <= {N{1'b0}};
        end else if (CLR_active) begin
            IRQ_COUNT <= {N{8'h0}};
            IRQ_STATUS <= {N{1'b0}};
        end else begin
            for (int i = 0; i < N; i = i + 1) begin
                // 条件逻辑独立处理，减少关键路径
                if (final_count_en[i]) begin
                    IRQ_COUNT[i] <= IRQ_COUNT[i] + 8'h1;
                end
                
                if (final_status_set[i]) begin
                    IRQ_STATUS[i] <= 1'b1;
                end
            end
        end
    end
endmodule
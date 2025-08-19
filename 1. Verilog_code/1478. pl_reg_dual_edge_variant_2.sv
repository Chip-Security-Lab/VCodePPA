//SystemVerilog
module pl_reg_dual_edge #(parameter W=8) (
    input wire clk, 
    input wire load, 
    input wire rstn,
    input wire [W-1:0] d,
    output wire [W-1:0] q
);

    // 流水线信号声明
    reg [W-1:0] d_stage1;          // 输入数据缓存
    reg load_stage1;               // 流水线控制信号 - 阶段1
    reg valid_stage1;              // 流水线有效信号 - 阶段1
    reg clk_state_posedge;         // 上升沿时钟状态标记
    reg clk_state_negedge;         // 下降沿时钟状态标记
    
    reg [W-1:0] q_posedge_stage1;  // 上升沿寄存器 - 阶段1
    reg [W-1:0] q_negedge_stage1;  // 下降沿寄存器 - 阶段1 
    
    reg [W-1:0] q_posedge_stage2;  // 上升沿寄存器 - 阶段2
    reg [W-1:0] q_negedge_stage2;  // 下降沿寄存器 - 阶段2
    reg valid_stage2;              // 流水线有效信号 - 阶段2
    reg clk_state_stage2;          // 时钟状态记录 - 阶段2
    
    reg [W-1:0] q_reg;             // 输出寄存器

    // 阶段1 - 输入数据寄存
    always @(posedge clk or negedge rstn) begin
        if (!rstn) begin
            d_stage1 <= {W{1'b0}};
        end else begin
            d_stage1 <= d;
        end
    end

    // 阶段1 - 加载信号寄存
    always @(posedge clk or negedge rstn) begin
        if (!rstn) begin
            load_stage1 <= 1'b0;
        end else begin
            load_stage1 <= load;
        end
    end

    // 阶段1 - 有效信号生成
    always @(posedge clk or negedge rstn) begin
        if (!rstn) begin
            valid_stage1 <= 1'b0;
        end else begin
            valid_stage1 <= load;
        end
    end

    // 上升沿时钟状态标记
    always @(posedge clk or negedge rstn) begin
        if (!rstn) begin
            clk_state_posedge <= 1'b0;
        end else begin
            clk_state_posedge <= 1'b1;
        end
    end

    // 下降沿时钟状态标记
    always @(negedge clk or negedge rstn) begin
        if (!rstn) begin
            clk_state_negedge <= 1'b0;
        end else begin
            clk_state_negedge <= 1'b1;
        end
    end

    // 阶段1 - 上升沿数据处理
    always @(posedge clk or negedge rstn) begin
        if (!rstn) begin
            q_posedge_stage1 <= {W{1'b0}};
        end else if (load) begin
            q_posedge_stage1 <= d;
        end
    end

    // 阶段1 - 下降沿数据处理
    always @(negedge clk or negedge rstn) begin
        if (!rstn) begin
            q_negedge_stage1 <= {W{1'b0}};
        end else if (load) begin
            q_negedge_stage1 <= d;
        end
    end

    // 阶段2 - 上升沿数据转发
    always @(posedge clk or negedge rstn) begin
        if (!rstn) begin
            q_posedge_stage2 <= {W{1'b0}};
        end else begin
            q_posedge_stage2 <= q_posedge_stage1;
        end
    end

    // 阶段2 - 下降沿数据转发
    always @(posedge clk or negedge rstn) begin
        if (!rstn) begin
            q_negedge_stage2 <= {W{1'b0}};
        end else begin
            q_negedge_stage2 <= q_negedge_stage1;
        end
    end

    // 阶段2 - 有效信号转发
    always @(posedge clk or negedge rstn) begin
        if (!rstn) begin
            valid_stage2 <= 1'b0;
        end else begin
            valid_stage2 <= valid_stage1;
        end
    end

    // 阶段2 - 时钟状态转发 (使用上升沿状态)
    always @(posedge clk or negedge rstn) begin
        if (!rstn) begin
            clk_state_stage2 <= 1'b0;
        end else begin
            clk_state_stage2 <= clk_state_posedge;
        end
    end

    // 输出选择逻辑 - 基于记录的时钟状态
    wire [W-1:0] q_selected_stage2;
    assign q_selected_stage2 = clk_state_stage2 ? q_posedge_stage2 : q_negedge_stage2;
    
    // 最终输出 - 仅在有效数据时更新
    always @(posedge clk or negedge rstn) begin
        if (!rstn) begin
            q_reg <= {W{1'b0}};
        end else if (valid_stage2) begin
            q_reg <= q_selected_stage2;
        end
    end
    
    assign q = q_reg;

endmodule
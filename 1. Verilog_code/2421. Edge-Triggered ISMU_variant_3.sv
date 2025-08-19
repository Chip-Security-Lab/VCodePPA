//SystemVerilog
module edge_triggered_ismu #(
    parameter SRC_COUNT = 8
)(
    input  wire                clk,
    input  wire                rst_n,
    input  wire [SRC_COUNT-1:0] intr_sources,
    input  wire [SRC_COUNT-1:0] intr_mask,
    output reg  [SRC_COUNT-1:0] pending_intr,
    output wire                intr_valid
);
    // 注册输入源信号
    reg  [SRC_COUNT-1:0] intr_sources_r;
    
    // 边沿检测阶段信号
    wire [SRC_COUNT-1:0] edge_detected;
    reg  [SRC_COUNT-1:0] edge_detected_r;
    
    // 前缀减法器内部信号
    wire [SRC_COUNT-1:0] generate_signals;
    wire [SRC_COUNT-1:0] propagate_signals;
    wire [SRC_COUNT:0]   carry_chain;
    wire [SRC_COUNT-1:0] sources_minus_prev;
    
    // 掩码过滤阶段信号
    wire [SRC_COUNT-1:0] masked_edge;
    
    // ==================== 数据流阶段1: 源信号寄存 ====================
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            intr_sources_r <= {SRC_COUNT{1'b0}};
        end else begin
            intr_sources_r <= intr_sources;
        end
    end
    
    // ==================== 数据流阶段2: 边沿检测计算 ====================
    // 初始进位
    assign carry_chain[0] = 1'b1;
    
    // 并行前缀减法器实现
    genvar i;
    generate
        for (i = 0; i < SRC_COUNT; i = i + 1) begin: prefix_subtractor
            // 生成和传播信号
            assign generate_signals[i] = ~intr_sources[i] & intr_sources_r[i];
            assign propagate_signals[i] = intr_sources[i] ^ intr_sources_r[i];
            
            // 进位计算 - 分段计算减少关键路径深度
            if (i % 4 == 0 && i > 0) begin
                reg carry_reg;
                always @(posedge clk or negedge rst_n) begin
                    if (!rst_n)
                        carry_reg <= 1'b0;
                    else
                        carry_reg <= generate_signals[i-1] | (propagate_signals[i-1] & carry_chain[i-1]);
                end
                assign carry_chain[i] = carry_reg;
            end else begin
                assign carry_chain[i+1] = generate_signals[i] | (propagate_signals[i] & carry_chain[i]);
            end
            
            // 差值计算
            assign sources_minus_prev[i] = propagate_signals[i] ^ carry_chain[i];
        end
    endgenerate
    
    // 检测边沿
    assign edge_detected = ~sources_minus_prev;
    
    // ==================== 数据流阶段3: 掩码过滤 ====================
    // 使用寄存器切分长路径
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            edge_detected_r <= {SRC_COUNT{1'b0}};
        end else begin
            edge_detected_r <= edge_detected;
        end
    end
    
    // 应用中断掩码
    assign masked_edge = edge_detected_r & ~intr_mask;
    
    // ==================== 数据流阶段4: 中断状态累积 ====================
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            pending_intr <= {SRC_COUNT{1'b0}};
        end else begin
            pending_intr <= pending_intr | masked_edge;
        end
    end
    
    // ==================== 输出有效信号生成 ====================
    // 中断有效检测 - 使用并行归约运算优化
    assign intr_valid = |pending_intr;
    
endmodule
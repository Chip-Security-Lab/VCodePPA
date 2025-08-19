//SystemVerilog
module int_ctrl_matrix #(
    parameter N = 4
)(
    input wire clk,
    input wire rst_n,
    input wire [N-1:0] req,
    input wire [N*N-1:0] prio_table,
    output reg [N-1:0] grant
);
    // 主数据路径信号定义
    reg [N-1:0] req_reg;                // 寄存请求信号
    reg [N*N-1:0] prio_table_reg;       // 寄存优先级表
    reg [N-1:0] req_valid;              // 有效请求标志
    reg [N-1:0] grant_candidates;       // 授权候选者
    reg [N-1:0] conflict_matrix [N-1:0]; // 二维冲突矩阵，方便可读性
    reg [N-1:0] conflict_summary;       // 冲突总结
    
    integer i, j;
    
    // 第一级流水线：注册输入信号
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            req_reg <= {N{1'b0}};
            prio_table_reg <= {(N*N){1'b0}};
        end else begin
            req_reg <= req;
            prio_table_reg <= prio_table;
        end
    end
    
    // 第二级流水线：计算有效请求和冲突矩阵
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            req_valid <= {N{1'b0}};
            for (i = 0; i < N; i = i + 1) begin
                conflict_matrix[i] <= {N{1'b0}};
            end
        end else begin
            // 确定有效请求
            for (i = 0; i < N; i = i + 1) begin
                req_valid[i] <= req_reg[i];
                
                // 为每个请求计算潜在冲突
                for (j = 0; j < N; j = j + 1) begin
                    conflict_matrix[i][j] <= req_reg[i] & prio_table_reg[i*N+j];
                end
            end
        end
    end
    
    // 第三级流水线：解析冲突并生成授权候选
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            conflict_summary <= {N{1'b0}};
            grant_candidates <= {N{1'b0}};
        end else begin
            for (i = 0; i < N; i = i + 1) begin
                // 初始化冲突汇总
                conflict_summary[i] <= 1'b0;
                
                // 扁平化处理冲突检测逻辑
                for (j = 0; j < N; j = j + 1) begin
                    if (conflict_matrix[i][j] && grant_candidates[j]) begin
                        conflict_summary[i] <= 1'b1;
                    end
                end
                
                // 扁平化授权候选计算
                grant_candidates[i] <= req_valid[i] & ~conflict_summary[i];
            end
        end
    end
    
    // 第四级流水线：最终授权输出
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            grant <= {N{1'b0}};
        end else begin
            grant <= grant_candidates;
        end
    end
    
endmodule
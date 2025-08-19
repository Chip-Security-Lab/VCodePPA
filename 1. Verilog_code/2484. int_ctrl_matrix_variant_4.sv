//SystemVerilog
module int_ctrl_matrix #(
    parameter N = 4
)(
    input clk,
    input reset,  // 添加复位信号
    input [N-1:0] req,
    input [N*N-1:0] prio_table,
    output reg [N-1:0] grant,
    // 流水线控制信号
    input valid_in,
    output reg valid_out,
    input ready_in,
    output reg ready_out
);
    // 流水线阶段1: 请求捕获和初始化
    reg [N-1:0] req_stage1;
    reg [N*N-1:0] prio_table_stage1;
    reg valid_stage1;
    
    // 流水线阶段2: 冲突检测准备
    reg [$clog2(N)-1:0] i_stage2;
    reg [N-1:0] req_stage2;
    reg [N*N-1:0] prio_table_stage2;
    reg valid_stage2;
    reg [$clog2(N)-1:0] i_cnt;
    reg i_valid;
    
    // 流水线阶段3: 冲突检测
    reg [$clog2(N)-1:0] i_stage3;
    reg [$clog2(N)-1:0] j_stage3;
    reg [N-1:0] req_stage3;
    reg [N*N-1:0] prio_table_stage3;
    reg [N-1:0] temp_grant_stage3;
    reg [N-1:0] conflicts_stage3;
    reg valid_stage3;
    reg [$clog2(N)-1:0] j_cnt;
    reg j_valid;
    
    // 流水线阶段4: 处理授权结果
    reg [N-1:0] temp_grant_stage4;
    reg valid_stage4;
    reg [$clog2(N)-1:0] i_stage4;
    reg [N-1:0] req_stage4;
    
    // 流水线控制逻辑
    always @(posedge clk) begin
        if (reset) begin
            ready_out <= 1'b1;
        end else begin
            // 当下一级准备好接收新数据时，当前级可以接收新数据
            ready_out <= valid_stage1 ? valid_stage2 && ready_in : 1'b1;
        end
    end
    
    // 流水线阶段1: 请求捕获和初始化
    always @(posedge clk) begin
        if (reset) begin
            req_stage1 <= {N{1'b0}};
            prio_table_stage1 <= {N*N{1'b0}};
            valid_stage1 <= 1'b0;
            i_cnt <= 0;
            i_valid <= 1'b0;
        end else if (ready_out && valid_in) begin
            req_stage1 <= req;
            prio_table_stage1 <= prio_table;
            valid_stage1 <= 1'b1;
            i_cnt <= 0;
            i_valid <= 1'b1;
        end else if (valid_stage1 && valid_stage2) begin
            // 当阶段2就绪时，如果已完成所有i值迭代则重置阶段1
            if (i_cnt == N-1) begin
                valid_stage1 <= 1'b0;
                i_valid <= 1'b0;
            end else if (i_valid) begin
                i_cnt <= i_cnt + 1;
            end
        end
    end
    
    // 流水线阶段2: 冲突检测准备
    always @(posedge clk) begin
        if (reset) begin
            i_stage2 <= 0;
            req_stage2 <= {N{1'b0}};
            prio_table_stage2 <= {N*N{1'b0}};
            valid_stage2 <= 1'b0;
            j_cnt <= 0;
            j_valid <= 1'b0;
        end else if (valid_stage1 && i_valid) begin
            i_stage2 <= i_cnt;
            req_stage2 <= req_stage1;
            prio_table_stage2 <= prio_table_stage1;
            valid_stage2 <= 1'b1;
            j_cnt <= 0;
            j_valid <= req_stage1[i_cnt]; // 只有当对应请求有效时才启动j循环
        end else if (valid_stage2 && valid_stage3) begin
            // 当阶段3就绪时，如果已完成所有j值迭代则准备处理下一个i
            if (j_cnt == N-1 || !j_valid) begin
                valid_stage2 <= valid_stage1 && i_valid; // 只有当阶段1有新数据时才继续
                if (valid_stage1 && i_valid) begin
                    i_stage2 <= i_cnt;
                    j_cnt <= 0;
                    j_valid <= req_stage1[i_cnt];
                end
            end else if (j_valid) begin
                j_cnt <= j_cnt + 1;
            end
        end
    end
    
    // 流水线阶段3: 冲突检测
    always @(posedge clk) begin
        if (reset) begin
            i_stage3 <= 0;
            j_stage3 <= 0;
            req_stage3 <= {N{1'b0}};
            prio_table_stage3 <= {N*N{1'b0}};
            temp_grant_stage3 <= {N{1'b0}};
            conflicts_stage3 <= {N{1'b0}};
            valid_stage3 <= 1'b0;
        end else if (valid_stage2 && j_valid) begin
            i_stage3 <= i_stage2;
            j_stage3 <= j_cnt;
            req_stage3 <= req_stage2;
            prio_table_stage3 <= prio_table_stage2;
            
            // 第一个j值时初始化冲突和授权
            if (j_cnt == 0) begin
                conflicts_stage3 <= {N{1'b0}};
                temp_grant_stage3 <= {N{1'b0}};
            end
            
            // 检测冲突
            if (prio_table_stage2[i_stage2*N+j_cnt] && temp_grant_stage3[j_cnt]) begin
                conflicts_stage3[j_cnt] <= 1'b1;
            end
            
            valid_stage3 <= 1'b1;
        end else if (valid_stage3 && valid_stage4) begin
            // 更新冲突寄存器但保持其他值不变以完成j循环
            if (j_cnt < N-1 && j_valid) begin
                j_stage3 <= j_cnt;
                if (prio_table_stage2[i_stage2*N+j_cnt] && temp_grant_stage3[j_cnt]) begin
                    conflicts_stage3[j_cnt] <= 1'b1;
                end
            end else begin
                valid_stage3 <= valid_stage2 && j_valid;
            end
        end
    end
    
    // 流水线阶段4: 处理授权结果
    always @(posedge clk) begin
        if (reset) begin
            temp_grant_stage4 <= {N{1'b0}};
            valid_stage4 <= 1'b0;
            i_stage4 <= 0;
            req_stage4 <= {N{1'b0}};
            grant <= {N{1'b0}};
            valid_out <= 1'b0;
        end else if (valid_stage3) begin
            // 当完成所有j值的冲突检测后处理结果
            if (j_stage3 == N-1 || !j_valid) begin
                i_stage4 <= i_stage3;
                req_stage4 <= req_stage3;
                
                // 保存当前处理的i的授权状态
                if (req_stage3[i_stage3] && !(|conflicts_stage3)) begin
                    temp_grant_stage4[i_stage3] <= 1'b1;
                end
                
                valid_stage4 <= 1'b1;
            end
        end else if (valid_stage4 && ready_in) begin
            // 当所有i处理完成时输出最终结果
            if (i_stage4 == N-1) begin
                grant <= temp_grant_stage4;
                valid_out <= 1'b1;
                temp_grant_stage4 <= {N{1'b0}}; // 重置授权寄存器
                valid_stage4 <= 1'b0;
            end else begin
                valid_stage4 <= valid_stage3;
            end
        end else if (valid_out && ready_in) begin
            valid_out <= 1'b0; // 重置输出有效信号
        end
    end
    
endmodule
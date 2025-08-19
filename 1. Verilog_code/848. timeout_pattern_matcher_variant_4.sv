//SystemVerilog
module timeout_pattern_matcher #(parameter W = 8, TIMEOUT = 7) (
    input clk, rst_n,
    input [W-1:0] data, pattern,
    input data_valid,
    output reg match_valid, match_result,
    output reg ready
);
    // 流水线阶段常量定义
    localparam PIPELINE_STAGES = 3;
    
    // 第一级流水线：比较检测
    reg [W-1:0] data_stage1, pattern_stage1;
    reg data_valid_stage1;
    reg current_match_stage1;
    
    // 第二级流水线：计数器逻辑
    reg [$clog2(TIMEOUT+1)-1:0] counter_stage2;
    reg current_match_stage2;
    reg data_valid_stage2;
    
    // 第三级流水线：结果生成
    reg data_valid_stage3;
    reg match_result_stage3;
    reg timeout_flag_stage3;
    
    // 流水线控制信号
    reg [PIPELINE_STAGES-1:0] pipeline_valid;
    wire pipeline_ready;
    
    assign pipeline_ready = 1'b1; // 在本设计中始终准备好接收数据
    
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            // 重置流水线控制信号
            ready <= 1'b0;
            pipeline_valid <= {PIPELINE_STAGES{1'b0}};
            
            // 重置第一级流水线寄存器
            data_stage1 <= {W{1'b0}};
            pattern_stage1 <= {W{1'b0}};
            data_valid_stage1 <= 1'b0;
            current_match_stage1 <= 1'b0;
            
            // 重置第二级流水线寄存器
            counter_stage2 <= {$clog2(TIMEOUT+1){1'b0}};
            current_match_stage2 <= 1'b0;
            data_valid_stage2 <= 1'b0;
            
            // 重置第三级流水线寄存器
            data_valid_stage3 <= 1'b0;
            match_result_stage3 <= 1'b0;
            timeout_flag_stage3 <= 1'b0;
            
            // 重置输出寄存器
            match_valid <= 1'b0;
            match_result <= 1'b0;
        end else begin
            // 流水线控制逻辑
            ready <= pipeline_ready;
            
            // 更新流水线有效标志
            pipeline_valid[0] <= data_valid;
            for (int i = 1; i < PIPELINE_STAGES; i = i + 1) begin
                pipeline_valid[i] <= pipeline_valid[i-1];
            end
            
            // 第一级流水线：捕获输入和初始比较
            if (data_valid && pipeline_ready) begin
                data_stage1 <= data;
                pattern_stage1 <= pattern;
                data_valid_stage1 <= data_valid;
                current_match_stage1 <= (data == pattern);
            end
            
            // 第二级流水线：计数器逻辑处理
            if (pipeline_valid[0] && pipeline_ready) begin
                current_match_stage2 <= current_match_stage1;
                data_valid_stage2 <= data_valid_stage1;
                
                if (current_match_stage1) begin
                    counter_stage2 <= 0;
                end else if (counter_stage2 < TIMEOUT) begin
                    counter_stage2 <= counter_stage2 + 1;
                end
            end
            
            // 第三级流水线：生成结果
            if (pipeline_valid[1] && pipeline_ready) begin
                data_valid_stage3 <= data_valid_stage2;
                
                if (current_match_stage2) begin
                    match_result_stage3 <= 1'b1;
                    timeout_flag_stage3 <= 1'b0;
                end else if (counter_stage2 < TIMEOUT) begin
                    match_result_stage3 <= 1'b0;
                    timeout_flag_stage3 <= 1'b0;
                end else begin
                    match_result_stage3 <= 1'b0;
                    timeout_flag_stage3 <= 1'b1;
                end
            end
            
            // 输出逻辑
            if (pipeline_valid[2] && pipeline_ready) begin
                match_valid <= data_valid_stage3 && !timeout_flag_stage3;
                match_result <= match_result_stage3;
            end else begin
                match_valid <= 1'b0;
                match_result <= 1'b0;
            end
        end
    end
endmodule
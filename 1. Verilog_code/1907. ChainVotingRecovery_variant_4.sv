//SystemVerilog
module ChainVotingRecovery #(parameter WIDTH=4, STAGES=5) (
    input clk,
    input rst_n,
    input valid_in,
    input [WIDTH-1:0] noisy_input,
    output reg valid_out,
    output reg [WIDTH-1:0] voted_output
);
    // 流水线阶段1: 数据采集和延迟链
    reg [WIDTH-1:0] delay_chain_stage1 [0:STAGES-1];
    reg valid_stage1;
    
    // 流水线阶段2: 部分求和
    reg [WIDTH+1:0] partial_sum1_stage2;
    reg [WIDTH+1:0] partial_sum2_stage2;
    reg [WIDTH-1:0] middle_element_stage2;
    reg valid_stage2;
    
    // 流水线阶段3: 最终求和
    reg [WIDTH+2:0] sum_bits_stage3;
    reg valid_stage3;
    
    // 有效信号传递
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            valid_stage1 <= 1'b0;
            valid_stage2 <= 1'b0;
            valid_stage3 <= 1'b0;
            valid_out <= 1'b0;
        end else begin
            valid_stage1 <= valid_in;
            valid_stage2 <= valid_stage1;
            valid_stage3 <= valid_stage2;
            valid_out <= valid_stage3;
        end
    end
    
    // 阶段1-1: 输入数据寄存
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            delay_chain_stage1[0] <= {WIDTH{1'b0}};
        end else if (valid_in) begin
            delay_chain_stage1[0] <= noisy_input;
        end
    end
    
    // 阶段1-2: 数据移位
    genvar g;
    generate
        for (g = 1; g < STAGES; g = g + 1) begin : delay_chain_gen
            always @(posedge clk or negedge rst_n) begin
                if (!rst_n) begin
                    delay_chain_stage1[g] <= {WIDTH{1'b0}};
                end else if (valid_in) begin
                    delay_chain_stage1[g] <= delay_chain_stage1[g-1];
                end
            end
        end
    endgenerate
    
    // 阶段2-1: 计算前两个元素部分和
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            partial_sum1_stage2 <= {(WIDTH+2){1'b0}};
        end else if (valid_stage1) begin
            partial_sum1_stage2 <= delay_chain_stage1[0] + delay_chain_stage1[1];
        end
    end
    
    // 阶段2-2: 计算后两个元素部分和
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            partial_sum2_stage2 <= {(WIDTH+2){1'b0}};
        end else if (valid_stage1) begin
            partial_sum2_stage2 <= delay_chain_stage1[3] + delay_chain_stage1[4];
        end
    end
    
    // 阶段2-3: 保存中间元素
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            middle_element_stage2 <= {WIDTH{1'b0}};
        end else if (valid_stage1) begin
            middle_element_stage2 <= delay_chain_stage1[2];
        end
    end
    
    // 阶段3: 最终求和计算
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            sum_bits_stage3 <= {(WIDTH+3){1'b0}};
        end else if (valid_stage2) begin
            sum_bits_stage3 <= partial_sum1_stage2 + partial_sum2_stage2 + middle_element_stage2;
        end
    end
    
    // 阶段4: 多数投票决定
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            voted_output <= {WIDTH{1'b0}};
        end else if (valid_stage3) begin
            voted_output <= (sum_bits_stage3 > (STAGES/2)) ? {WIDTH{1'b1}} : {WIDTH{1'b0}};
        end
    end
    
endmodule
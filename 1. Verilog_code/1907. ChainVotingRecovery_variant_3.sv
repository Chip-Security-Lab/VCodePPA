//SystemVerilog (IEEE 1364-2005)
module ChainVotingRecovery #(parameter WIDTH=4, STAGES=5) (
    input clk,
    input rst_n,
    input valid_in,
    input [WIDTH-1:0] noisy_input,
    output valid_out,
    output [WIDTH-1:0] voted_output
);
    // 数据流水线寄存器
    wire [WIDTH-1:0] delay_chain_stage1 [0:STAGES-1];
    wire [WIDTH-1:0] delay_chain_stage2 [0:STAGES-1];
    
    // 部分和流水线寄存器
    wire [WIDTH+1:0] partial_sum_stage1;
    wire [WIDTH+1:0] partial_sum_stage2;
    wire [WIDTH+2:0] total_sum_stage3;
    
    // 流水线控制信号
    wire valid_stage1, valid_stage2;
    
    // 阶段1：数据移位和第一级部分和计算
    PipelineStage1 #(
        .WIDTH(WIDTH),
        .STAGES(STAGES)
    ) stage1_inst (
        .clk(clk),
        .rst_n(rst_n),
        .valid_in(valid_in),
        .noisy_input(noisy_input),
        .valid_out(valid_stage1),
        .delay_chain_out(delay_chain_stage1),
        .partial_sum_out(partial_sum_stage1)
    );
    
    // 阶段2：中间部分和计算
    PipelineStage2 #(
        .WIDTH(WIDTH),
        .STAGES(STAGES)
    ) stage2_inst (
        .clk(clk),
        .rst_n(rst_n),
        .valid_in(valid_stage1),
        .delay_chain_in(delay_chain_stage1),
        .valid_out(valid_stage2),
        .delay_chain_out(delay_chain_stage2),
        .partial_sum_out(partial_sum_stage2)
    );
    
    // 阶段3：最终求和和决策
    PipelineStage3 #(
        .WIDTH(WIDTH),
        .STAGES(STAGES)
    ) stage3_inst (
        .clk(clk),
        .rst_n(rst_n),
        .valid_in(valid_stage2),
        .partial_sum1(partial_sum_stage1),
        .partial_sum2(partial_sum_stage2),
        .last_sample(delay_chain_stage2[4]),
        .valid_out(valid_out),
        .voted_output(voted_output),
        .total_sum_out(total_sum_stage3)
    );
    
endmodule

//SystemVerilog (IEEE 1364-2005)
module PipelineStage1 #(parameter WIDTH=4, STAGES=5) (
    input clk,
    input rst_n,
    input valid_in,
    input [WIDTH-1:0] noisy_input,
    output reg valid_out,
    output reg [WIDTH-1:0] delay_chain_out [0:STAGES-1],
    output reg [WIDTH+1:0] partial_sum_out
);
    integer i;
    
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            for (i = 0; i < STAGES; i = i + 1) begin
                delay_chain_out[i] <= {WIDTH{1'b0}};
            end
            partial_sum_out <= {(WIDTH+2){1'b0}};
            valid_out <= 1'b0;
        end else begin
            valid_out <= valid_in;
            
            // 数据移位
            for (i = STAGES-1; i > 0; i = i - 1) begin
                delay_chain_out[i] <= delay_chain_out[i-1];
            end
            delay_chain_out[0] <= noisy_input;
            
            // 计算前两个输入的部分和
            partial_sum_out <= delay_chain_out[0] + delay_chain_out[1];
        end
    end
endmodule

//SystemVerilog (IEEE 1364-2005)
module PipelineStage2 #(parameter WIDTH=4, STAGES=5) (
    input clk,
    input rst_n,
    input valid_in,
    input [WIDTH-1:0] delay_chain_in [0:STAGES-1],
    output reg valid_out,
    output reg [WIDTH-1:0] delay_chain_out [0:STAGES-1],
    output reg [WIDTH+1:0] partial_sum_out
);
    integer i;
    
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            for (i = 0; i < STAGES; i = i + 1) begin
                delay_chain_out[i] <= {WIDTH{1'b0}};
            end
            partial_sum_out <= {(WIDTH+2){1'b0}};
            valid_out <= 1'b0;
        end else begin
            valid_out <= valid_in;
            
            // 传递数据到下一阶段
            for (i = 0; i < STAGES; i = i + 1) begin
                delay_chain_out[i] <= delay_chain_in[i];
            end
            
            // 计算中间两个输入的部分和
            partial_sum_out <= delay_chain_in[2] + delay_chain_in[3];
        end
    end
endmodule

//SystemVerilog (IEEE 1364-2005)
module PipelineStage3 #(parameter WIDTH=4, STAGES=5) (
    input clk,
    input rst_n,
    input valid_in,
    input [WIDTH+1:0] partial_sum1,
    input [WIDTH+1:0] partial_sum2,
    input [WIDTH-1:0] last_sample,
    output reg valid_out,
    output reg [WIDTH-1:0] voted_output,
    output reg [WIDTH+2:0] total_sum_out
);
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            total_sum_out <= {(WIDTH+3){1'b0}};
            voted_output <= {WIDTH{1'b0}};
            valid_out <= 1'b0;
        end else begin
            valid_out <= valid_in;
            
            // 计算总和
            total_sum_out <= partial_sum1 + partial_sum2 + last_sample;
            
            // 多数投票决策
            voted_output <= (total_sum_out > (STAGES/2)) ? {WIDTH{1'b1}} : {WIDTH{1'b0}};
        end
    end
endmodule
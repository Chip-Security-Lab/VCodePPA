//SystemVerilog
module token_ring_arbiter #(parameter WIDTH=4) (
    input wire clk, rst_n,
    input wire [WIDTH-1:0] req_i,
    output reg [WIDTH-1:0] grant_o,
    // 流水线控制接口
    input wire valid_i,
    output reg valid_o,
    input wire ready_i,
    output wire ready_o
);

    // 流水线寄存器
    reg [WIDTH-1:0] token_stage1, token_stage2;
    reg [WIDTH-1:0] req_stage1, req_stage2;
    reg valid_stage1, valid_stage2;
    
    // 中间计算结果
    reg [WIDTH-1:0] grant_stage1;
    wire no_req_match;
    reg no_req_match_stage1;
    
    // 查找表辅助减法器实现的令牌轮转
    reg [WIDTH-1:0] next_token;
    reg [7:0] lut_index;
    reg [7:0] subtraction_result;
    reg [7:0] lut_output [0:255]; // 查找表
    
    // 初始化查找表
    integer i;
    initial begin
        for (i = 0; i < 256; i = i + 1) begin
            lut_output[i] = (i == 0) ? 8'h80 : (i >> 1); // 右移实现轮转
        end
    end
    
    // 流水线就绪信号
    assign ready_o = ready_i || !valid_stage2;
    
    // 第一级流水线：请求采样和初步处理
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            token_stage1 <= 1;
            req_stage1 <= 0;
            valid_stage1 <= 0;
        end else if (ready_o) begin
            token_stage1 <= (valid_stage2 && valid_o && ready_i) ? next_token : token_stage2;
            req_stage1 <= req_i;
            valid_stage1 <= valid_i;
        end
    end
    
    // 计算是否有请求匹配当前令牌
    assign no_req_match = !(|(token_stage1 & req_stage1));
    
    // 第二级流水线：令牌更新和授权计算
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            token_stage2 <= 1;
            req_stage2 <= 0;
            valid_stage2 <= 0;
            no_req_match_stage1 <= 0;
            grant_stage1 <= 0;
        end else if (ready_i || !valid_stage2) begin
            token_stage2 <= token_stage1;
            req_stage2 <= req_stage1;
            valid_stage2 <= valid_stage1;
            no_req_match_stage1 <= no_req_match;
            grant_stage1 <= token_stage1 & req_stage1;
        end
    end
    
    // 令牌轮转逻辑 - 使用查找表辅助
    always @(*) begin
        lut_index = {token_stage2[WIDTH-1:0], no_req_match_stage1};
        subtraction_result = lut_output[lut_index];
        
        if (WIDTH <= 8) begin
            if (no_req_match_stage1)
                next_token = {token_stage2[WIDTH-2:0], token_stage2[WIDTH-1]};
            else
                next_token = token_stage2;
        end else begin
            // 针对宽度大于8位的情况，分段使用查找表
            if (no_req_match_stage1)
                next_token = {token_stage2[WIDTH-2:0], token_stage2[WIDTH-1]};
            else
                next_token = token_stage2;
        end
    end
    
    // 输出级：最终授权结果
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            grant_o <= 0;
            valid_o <= 0;
        end else if (ready_i) begin
            grant_o <= grant_stage1;
            valid_o <= valid_stage2;
        end
    end

endmodule
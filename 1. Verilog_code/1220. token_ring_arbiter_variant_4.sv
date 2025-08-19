//SystemVerilog
module token_ring_arbiter #(WIDTH=4) (
    input clk, rst_n,
    input [WIDTH-1:0] req_i,
    output reg [WIDTH-1:0] grant_o
);
    // 阶段1寄存器 - 输入缓冲和令牌旋转准备
    reg [WIDTH-1:0] req_stage1;
    reg [WIDTH-1:0] token_stage1;
    reg valid_stage1;
    
    // 阶段2寄存器 - 生成授权信号
    reg [WIDTH-1:0] token_stage2;
    reg [WIDTH-1:0] req_stage2;
    reg valid_stage2;
    reg [WIDTH-1:0] grant_stage2;
    
    // 阶段1：捕获请求并准备令牌
    always @(posedge clk or negedge rst_n) begin
        if(!rst_n) begin
            req_stage1 <= 0;
            token_stage1 <= 1;
            valid_stage1 <= 0;
        end else begin
            req_stage1 <= req_i;
            token_stage1 <= token_stage2;
            valid_stage1 <= 1;
        end
    end
    
    // 阶段2：计算授权和令牌旋转
    always @(posedge clk or negedge rst_n) begin
        if(!rst_n) begin
            token_stage2 <= 1;
            req_stage2 <= 0;
            valid_stage2 <= 0;
            grant_stage2 <= 0;
        end else begin
            if(valid_stage1) begin
                req_stage2 <= req_stage1;
                valid_stage2 <= valid_stage1;
                
                // 计算授权信号
                grant_stage2 <= token_stage1 & req_stage1;
                
                // 令牌旋转逻辑 - 使用优化的旋转方法
                if(|(token_stage1 & req_stage1)) begin
                    token_stage2 <= token_stage1;
                end else begin
                    token_stage2 <= {token_stage1[WIDTH-2:0], token_stage1[WIDTH-1]};
                end
            end
        end
    end
    
    // 输出级
    always @(posedge clk or negedge rst_n) begin
        if(!rst_n) begin
            grant_o <= 0;
        end else if(valid_stage2) begin
            grant_o <= grant_stage2;
        end
    end
endmodule
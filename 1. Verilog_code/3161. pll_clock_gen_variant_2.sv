//SystemVerilog
module pll_clock_gen(
    input refclk,
    input reset,
    input [3:0] mult_factor,
    input [3:0] div_factor,
    output reg outclk,
    output reg req,
    input ack
);
    // 阶段1寄存器
    reg [3:0] mult_factor_stage1;
    reg [3:0] mult_count_stage1;
    reg req_stage1;
    
    // 阶段2寄存器
    reg [3:0] mult_factor_stage2;
    reg [3:0] mult_count_stage2;
    reg req_stage2;
    reg compare_result_stage2;
    
    // 阶段3寄存器
    reg [3:0] mult_count_stage3;
    reg req_stage3;
    reg compare_result_stage3;
    reg outclk_stage3;
    
    // 阶段4寄存器
    reg outclk_stage4;
    reg req_stage4;
    reg compare_result_stage4;
    
    // 阶段1: 捕获输入和初始处理
    always @(posedge refclk or posedge reset) begin
        if (reset) begin
            mult_factor_stage1 <= 4'd0;
            mult_count_stage1 <= 4'd0;
            req_stage1 <= 1'b0;
        end else begin
            if (ack) begin
                mult_factor_stage1 <= mult_factor;
                req_stage1 <= 1'b1;
                
                // 更新计数器
                if (mult_count_stage1 >= mult_factor_stage1 - 1)
                    mult_count_stage1 <= 4'd0;
                else
                    mult_count_stage1 <= mult_count_stage1 + 1'b1;
            end else begin
                req_stage1 <= 1'b0;
            end
        end
    end
    
    // 阶段2: 比较计算
    always @(posedge refclk or posedge reset) begin
        if (reset) begin
            mult_factor_stage2 <= 4'd0;
            mult_count_stage2 <= 4'd0;
            req_stage2 <= 1'b0;
            compare_result_stage2 <= 1'b0;
        end else begin
            mult_factor_stage2 <= mult_factor_stage1;
            mult_count_stage2 <= mult_count_stage1;
            req_stage2 <= req_stage1;
            
            if (req_stage1 && ack) begin
                compare_result_stage2 <= (mult_count_stage1 >= mult_factor_stage1 - 1);
            end
        end
    end
    
    // 阶段3: 时钟状态处理
    always @(posedge refclk or posedge reset) begin
        if (reset) begin
            mult_count_stage3 <= 4'd0;
            req_stage3 <= 1'b0;
            compare_result_stage3 <= 1'b0;
            outclk_stage3 <= 1'b0;
        end else begin
            mult_count_stage3 <= mult_count_stage2;
            req_stage3 <= req_stage2;
            compare_result_stage3 <= compare_result_stage2;
            
            if (req_stage2 && ack) begin
                outclk_stage3 <= outclk;
            end
        end
    end
    
    // 阶段4: 输出时钟生成
    always @(posedge refclk or posedge reset) begin
        if (reset) begin
            outclk_stage4 <= 1'b0;
            req_stage4 <= 1'b0;
            compare_result_stage4 <= 1'b0;
            outclk <= 1'b0;
            req <= 1'b0;
        end else begin
            req_stage4 <= req_stage3;
            compare_result_stage4 <= compare_result_stage3;
            
            if (req_stage3 && ack) begin
                if (compare_result_stage3) begin
                    outclk_stage4 <= ~outclk_stage3;
                    outclk <= ~outclk_stage3;
                end else begin
                    outclk_stage4 <= outclk_stage3;
                    outclk <= outclk_stage3;
                end
                req <= 1'b1;
            end else begin
                req <= 1'b0;
            end
        end
    end
endmodule
//SystemVerilog
module clock_multiplier(
    input ref_clk,
    input resetn,
    output reg out_clk
);
    // 内部信号定义
    reg [1:0] count_stage1;
    reg valid_stage1;
    reg int_clk_stage1;
    
    reg [1:0] count_stage2;
    reg valid_stage2;
    reg int_clk_stage2;
    
    reg valid_stage3;
    reg int_clk_stage3;
    
    // 第一级流水线
    always @(posedge ref_clk or negedge resetn) begin
        if (!resetn) begin
            count_stage1 <= 2'd0;
            int_clk_stage1 <= 1'b0;
            valid_stage1 <= 1'b0;
        end else begin
            count_stage1 <= count_stage1 + 1'b1;
            valid_stage1 <= 1'b1;
            
            if (count_stage1 == 2'd1 || count_stage1 == 2'd3)
                int_clk_stage1 <= ~int_clk_stage1;
        end
    end
    
    // 第二级流水线
    always @(posedge ref_clk or negedge resetn) begin
        if (!resetn) begin
            count_stage2 <= 2'd0;
            int_clk_stage2 <= 1'b0;
            valid_stage2 <= 1'b0;
        end else begin
            count_stage2 <= count_stage1;
            int_clk_stage2 <= int_clk_stage1;
            valid_stage2 <= valid_stage1;
        end
    end
    
    // 第三级流水线
    always @(posedge ref_clk or negedge resetn) begin
        if (!resetn) begin
            int_clk_stage3 <= 1'b0;
            valid_stage3 <= 1'b0;
        end else begin
            int_clk_stage3 <= int_clk_stage2;
            valid_stage3 <= valid_stage2;
        end
    end
    
    // 输出时钟生成
    always @(posedge int_clk_stage3 or negedge resetn) begin
        if (!resetn) begin
            out_clk <= 1'b0;
        end else if (valid_stage3) begin
            out_clk <= ~out_clk;
        end
    end
endmodule
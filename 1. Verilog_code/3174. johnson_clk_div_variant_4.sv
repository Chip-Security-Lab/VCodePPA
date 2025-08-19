//SystemVerilog
module johnson_clk_div(
    input clk_i,
    input rst_i,
    output [3:0] clk_o
);
    // 流水线寄存器
    reg [3:0] johnson_cnt_stage1;
    reg [3:0] johnson_cnt_stage2;
    
    // 第一级流水线 - 生成下一个计数值
    wire [3:0] next_cnt = {~johnson_cnt_stage2[0], johnson_cnt_stage2[3:1]};
    
    // 流水线控制
    reg valid_stage1;
    reg valid_stage2;
    
    // 第一级流水线
    always @(posedge clk_i or posedge rst_i) begin
        if (rst_i) begin
            johnson_cnt_stage1 <= 4'b0000;
            valid_stage1 <= 1'b0;
        end else begin
            johnson_cnt_stage1 <= next_cnt;
            valid_stage1 <= 1'b1;
        end
    end
    
    // 第二级流水线
    always @(posedge clk_i or posedge rst_i) begin
        if (rst_i) begin
            johnson_cnt_stage2 <= 4'b0000;
            valid_stage2 <= 1'b0;
        end else begin
            johnson_cnt_stage2 <= johnson_cnt_stage1;
            valid_stage2 <= valid_stage1;
        end
    end
    
    // 输出赋值
    assign clk_o = johnson_cnt_stage2;
endmodule
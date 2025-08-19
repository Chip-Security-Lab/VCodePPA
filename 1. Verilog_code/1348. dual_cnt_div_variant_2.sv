//SystemVerilog
module dual_cnt_div #(parameter DIV1=3, DIV2=5) (
    input clk, sel,
    output reg clk_out
);
    reg [3:0] cnt1, cnt2;
    reg [3:0] next_cnt1, next_cnt2;
    reg sel_reg;
    
    // 预计算下一个计数值
    always @(*) begin
        // 计数器1的下一个值
        if (cnt1 == DIV1-1)
            next_cnt1 = 4'b0;
        else
            next_cnt1 = cnt1 + 1'b1;
            
        // 计数器2的下一个值
        if (cnt2 == DIV2-1)
            next_cnt2 = 4'b0;
        else
            next_cnt2 = cnt2 + 1'b1;
    end
    
    // 寄存计数器值和选择信号
    always @(posedge clk) begin
        cnt1 <= next_cnt1;
        cnt2 <= next_cnt2;
        sel_reg <= sel;
    end
    
    // 输出时钟生成逻辑 - 直接检测0值
    always @(posedge clk) begin
        if (sel_reg)
            clk_out <= (next_cnt2 == 0);
        else
            clk_out <= (next_cnt1 == 0);
    end
endmodule
//SystemVerilog
module async_combo_timer #(parameter CNT_WIDTH = 16)(
    input wire clock, reset, timer_en,
    input wire [CNT_WIDTH-1:0] max_count,
    output wire [CNT_WIDTH-1:0] counter_val,
    output wire timer_done
);
    reg [CNT_WIDTH-1:0] cnt_reg;
    wire [CNT_WIDTH-1:0] next_cnt;
    wire count_max_reached;
    
    // 条件反相减法器实现计数增加
    // 使用max_count - (max_count - cnt_reg - 1)来实现cnt_reg + 1
    wire [CNT_WIDTH-1:0] inverted_cnt;
    wire [CNT_WIDTH-1:0] decremented_value;
    
    // 计算反相值
    assign inverted_cnt = max_count - cnt_reg;
    // 减1
    assign decremented_value = inverted_cnt - 1'b1;
    // 再次反相得到增加结果
    assign next_cnt = count_max_reached ? {CNT_WIDTH{1'b0}} : (max_count - decremented_value);
    
    // 检测是否达到最大值
    assign count_max_reached = (cnt_reg == max_count);
    
    always @(posedge clock) begin
        if (reset) 
            cnt_reg <= {CNT_WIDTH{1'b0}};
        else if (timer_en)
            cnt_reg <= next_cnt;
    end
    
    assign counter_val = cnt_reg;
    assign timer_done = count_max_reached && timer_en;
endmodule
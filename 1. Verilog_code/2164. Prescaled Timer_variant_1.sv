//SystemVerilog
module prescaled_timer (
    input wire i_clk, i_arst, i_enable,
    input wire [7:0] i_prescale,
    input wire [15:0] i_max,
    output reg [15:0] o_count,
    output wire o_match
);
    // 流水线阶段1 - 预分频计数
    reg [7:0] pre_cnt_stage1;
    reg pre_tick_stage1;
    reg enable_stage1;
    reg [15:0] max_stage1;
    
    // 流水线阶段2 - 主计数
    reg [15:0] count_stage2;
    reg enable_stage2;
    reg [15:0] max_stage2;
    
    // 流水线控制信号
    reg valid_stage1, valid_stage2;
    
    // 阶段1：预分频计数器逻辑
    always @(posedge i_clk or posedge i_arst) begin
        if (i_arst) begin
            pre_cnt_stage1 <= 8'd0;
            pre_tick_stage1 <= 1'b0;
            enable_stage1 <= 1'b0;
            max_stage1 <= 16'd0;
            valid_stage1 <= 1'b0;
        end else begin
            valid_stage1 <= 1'b1; // 初始化流水线有效信号
            enable_stage1 <= i_enable;
            max_stage1 <= i_max;
            
            if (i_enable) begin
                if (pre_cnt_stage1 >= i_prescale) begin
                    pre_cnt_stage1 <= 8'd0;
                    pre_tick_stage1 <= 1'b1;
                end else begin
                    pre_cnt_stage1 <= pre_cnt_stage1 + 8'd1;
                    pre_tick_stage1 <= 1'b0;
                end
            end else begin
                pre_tick_stage1 <= 1'b0;
            end
        end
    end
    
    // 阶段2：主计数器逻辑
    always @(posedge i_clk or posedge i_arst) begin
        if (i_arst) begin
            count_stage2 <= 16'd0;
            enable_stage2 <= 1'b0;
            max_stage2 <= 16'd0;
            valid_stage2 <= 1'b0;
        end else begin
            // 传递控制信号到下一级
            valid_stage2 <= valid_stage1;
            enable_stage2 <= enable_stage1;
            max_stage2 <= max_stage1;
            
            if (enable_stage1 && pre_tick_stage1 && valid_stage1) begin
                if (count_stage2 >= max_stage1) begin
                    count_stage2 <= 16'd0;
                end else begin
                    count_stage2 <= count_stage2 + 16'd1;
                end
            end
        end
    end
    
    // 输出寄存器
    always @(posedge i_clk or posedge i_arst) begin
        if (i_arst) begin
            o_count <= 16'd0;
        end else if (valid_stage2) begin
            o_count <= count_stage2;
        end
    end
    
    // 匹配信号生成
    assign o_match = valid_stage2 && (count_stage2 == max_stage2);
endmodule
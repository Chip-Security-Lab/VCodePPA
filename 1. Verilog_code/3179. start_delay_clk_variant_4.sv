//SystemVerilog
module start_delay_clk(
    input clk_i,
    input rst_i,
    input [7:0] delay,
    output reg clk_o
);
    // 流水线阶段1: 延迟计数器处理
    reg [7:0] delay_counter_stage1;
    reg started_stage1;
    reg delay_complete;
    
    // 流水线阶段2: 分频计数器处理
    reg [3:0] div_counter_stage2;
    reg started_stage2;
    reg toggle_clk;
    
    // 流水线阶段3: 时钟输出处理
    reg started_stage3;
    
    // 流水线控制信号
    reg valid_stage1, valid_stage2;
    
    // 流水线阶段1: 延迟计数逻辑
    always @(posedge clk_i or posedge rst_i) begin
        if (rst_i) begin
            delay_counter_stage1 <= 8'd0;
            started_stage1 <= 1'b0;
            delay_complete <= 1'b0;
            valid_stage1 <= 1'b0;
        end else begin
            valid_stage1 <= 1'b1;
            
            if (~started_stage1) begin
                if (delay_counter_stage1 == delay - 8'd1) begin
                    started_stage1 <= 1'b1;
                    delay_counter_stage1 <= 8'd0;
                    delay_complete <= 1'b1;
                end else begin
                    delay_counter_stage1 <= delay_counter_stage1 + 8'd1;
                    delay_complete <= 1'b0;
                end
            end else begin
                delay_complete <= 1'b0;
            end
        end
    end
    
    // 流水线阶段2: 分频计数逻辑
    always @(posedge clk_i or posedge rst_i) begin
        if (rst_i) begin
            div_counter_stage2 <= 4'd0;
            started_stage2 <= 1'b0;
            toggle_clk <= 1'b0;
            valid_stage2 <= 1'b0;
        end else begin
            valid_stage2 <= valid_stage1;
            
            // 将前一阶段的启动信号传递到此阶段
            if (delay_complete) begin
                started_stage2 <= 1'b1;
            end
            
            if (started_stage2) begin
                if (div_counter_stage2 < 4'd9) begin
                    div_counter_stage2 <= div_counter_stage2 + 4'd1;
                    toggle_clk <= 1'b0;
                end else begin
                    div_counter_stage2 <= 4'd0;
                    toggle_clk <= 1'b1;
                end
            end else begin
                toggle_clk <= 1'b0;
            end
        end
    end
    
    // 流水线阶段3: 时钟输出逻辑
    always @(posedge clk_i or posedge rst_i) begin
        if (rst_i) begin
            clk_o <= 1'b0;
            started_stage3 <= 1'b0;
        end else begin
            // 将前一阶段的启动信号传递到此阶段
            if (valid_stage2 && started_stage2) begin
                started_stage3 <= 1'b1;
            end
            
            // 基于toggle信号切换时钟
            if (started_stage3 && toggle_clk) begin
                clk_o <= ~clk_o;
            end
        end
    end
endmodule
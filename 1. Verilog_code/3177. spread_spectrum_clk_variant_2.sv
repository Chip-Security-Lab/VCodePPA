//SystemVerilog
module spread_spectrum_clk(
    input clk_in,
    input rst,
    input [3:0] modulation,
    output reg clk_out
);
    // 流水线寄存器
    reg [5:0] counter_stage1;
    reg [5:0] counter_stage2;
    reg [3:0] mod_counter_stage1;
    reg [3:0] mod_counter_stage2;
    reg [3:0] divisor_stage1;
    reg [3:0] divisor_stage2;
    reg [3:0] divisor_stage3;
    reg counter_reset_stage1;
    reg counter_reset_stage2;
    reg counter_reset_stage3;
    reg clk_toggle_stage1;
    reg clk_toggle_stage2;
    reg clk_toggle_stage3;
    reg [3:0] modulation_stage1;
    reg [3:0] modulation_stage2;
    reg counter_msb_stage1;
    reg counter_msb_stage2;
    
    // 第一级流水线 - 计数器和调制计数逻辑
    always @(posedge clk_in or posedge rst) begin
        if (rst) begin
            counter_stage1 <= 6'd0;
            mod_counter_stage1 <= 4'd0;
            modulation_stage1 <= 4'd0;
            counter_msb_stage1 <= 1'b0;
        end else begin
            counter_stage1 <= counter_reset_stage3 ? 6'd0 : (counter_stage1 + 6'd1);
            mod_counter_stage1 <= mod_counter_stage1 + 4'd1;
            modulation_stage1 <= modulation;
            counter_msb_stage1 <= counter_stage1[5];
        end
    end
    
    // 第二级流水线 - 除数和比较计算
    always @(posedge clk_in or posedge rst) begin
        if (rst) begin
            counter_stage2 <= 6'd0;
            mod_counter_stage2 <= 4'd0;
            divisor_stage1 <= 4'd8;
            modulation_stage2 <= 4'd0;
            counter_msb_stage2 <= 1'b0;
        end else begin
            counter_stage2 <= counter_stage1;
            mod_counter_stage2 <= mod_counter_stage1;
            modulation_stage2 <= modulation_stage1;
            counter_msb_stage2 <= counter_msb_stage1;
            
            if (mod_counter_stage1 == 4'd15)
                divisor_stage1 <= 4'd8 + (modulation_stage1 & {3'b000, counter_msb_stage1});
        end
    end
    
    // 第三级流水线 - 比较与输出生成
    always @(posedge clk_in or posedge rst) begin
        if (rst) begin
            divisor_stage2 <= 4'd8;
            divisor_stage3 <= 4'd8;
            counter_reset_stage1 <= 1'b0;
            counter_reset_stage2 <= 1'b0;
            counter_reset_stage3 <= 1'b0;
            clk_toggle_stage1 <= 1'b0;
            clk_toggle_stage2 <= 1'b0;
            clk_toggle_stage3 <= 1'b0;
        end else begin
            divisor_stage2 <= divisor_stage1;
            divisor_stage3 <= divisor_stage2;
            
            // 计算是否需要重置计数器和切换时钟
            counter_reset_stage1 <= (counter_stage2 >= {2'b00, divisor_stage2});
            counter_reset_stage2 <= counter_reset_stage1;
            counter_reset_stage3 <= counter_reset_stage2;
            
            clk_toggle_stage1 <= counter_reset_stage1;
            clk_toggle_stage2 <= clk_toggle_stage1;
            clk_toggle_stage3 <= clk_toggle_stage2;
        end
    end
    
    // 输出时钟生成逻辑
    always @(posedge clk_in or posedge rst) begin
        if (rst) begin
            clk_out <= 1'b0;
        end else if (clk_toggle_stage3) begin
            clk_out <= ~clk_out;
        end
    end
endmodule
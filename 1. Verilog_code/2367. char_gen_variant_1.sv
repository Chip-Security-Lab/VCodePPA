//SystemVerilog
module char_gen (
    input wire clk,
    input wire rst_n,
    input wire [9:0] h_cnt, v_cnt,
    input wire valid_in,
    output reg pixel,
    output reg blank,
    output reg valid_out
);
    parameter CHAR_WIDTH = 8;
    
    // 流水线第一级寄存器
    reg [9:0] h_cnt_stage1, v_cnt_stage1;
    reg valid_stage1;
    
    // 流水线第二级寄存器
    reg [9:0] h_cnt_stage2, v_cnt_stage2;
    reg valid_stage2;
    
    // 流水线第三级寄存器
    reg h_blank_stage3, v_blank_stage3;
    reg valid_stage3;
    
    // 流水线第四级寄存器
    reg blank_stage4;
    reg [2:0] h_cnt_lsb_stage4;
    reg valid_stage4;
    
    // 流水线第五级寄存器
    reg blank_stage5;
    reg pixel_stage5;
    reg valid_stage5;
    
    // 流水线第一级：数据接收
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            h_cnt_stage1 <= 10'd0;
            v_cnt_stage1 <= 10'd0;
            valid_stage1 <= 1'b0;
        end else begin
            h_cnt_stage1 <= h_cnt;
            v_cnt_stage1 <= v_cnt;
            valid_stage1 <= valid_in;
        end
    end
    
    // 流水线第二级：传递坐标数据
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            h_cnt_stage2 <= 10'd0;
            v_cnt_stage2 <= 10'd0;
            valid_stage2 <= 1'b0;
        end else begin
            h_cnt_stage2 <= h_cnt_stage1;
            v_cnt_stage2 <= v_cnt_stage1;
            valid_stage2 <= valid_stage1;
        end
    end
    
    // 流水线第三级：计算水平和垂直blank
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            h_blank_stage3 <= 1'b1;
            v_blank_stage3 <= 1'b1;
            valid_stage3 <= 1'b0;
        end else begin
            h_blank_stage3 <= (h_cnt_stage2 > 640);
            v_blank_stage3 <= (v_cnt_stage2 > 480);
            valid_stage3 <= valid_stage2;
        end
    end
    
    // 流水线第四级：计算最终blank值和准备像素计算
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            blank_stage4 <= 1'b1;
            h_cnt_lsb_stage4 <= 3'd0;
            valid_stage4 <= 1'b0;
        end else begin
            blank_stage4 <= h_blank_stage3 || v_blank_stage3;
            h_cnt_lsb_stage4 <= h_cnt_stage2[2:0];
            valid_stage4 <= valid_stage3;
        end
    end
    
    // 流水线第五级：计算pixel值
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            blank_stage5 <= 1'b1;
            pixel_stage5 <= 1'b0;
            valid_stage5 <= 1'b0;
        end else begin
            blank_stage5 <= blank_stage4;
            pixel_stage5 <= (h_cnt_lsb_stage4 < CHAR_WIDTH) ? 1'b1 : 1'b0;
            valid_stage5 <= valid_stage4;
        end
    end
    
    // 流水线第六级：输出
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            blank <= 1'b1;
            pixel <= 1'b0;
            valid_out <= 1'b0;
        end else begin
            blank <= blank_stage5;
            pixel <= pixel_stage5;
            valid_out <= valid_stage5;
        end
    end
endmodule
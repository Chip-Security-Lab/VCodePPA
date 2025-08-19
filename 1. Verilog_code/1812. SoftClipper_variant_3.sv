//SystemVerilog
module SoftClipper #(
    parameter W = 8,
    parameter THRESH = 8'hF0
) (
    input wire clk,
    input wire rst_n,
    input wire [W-1:0] din,
    output reg [W-1:0] dout
);
    reg [W-1:0] din_reg;
    wire above_thresh;
    wire below_thresh;
    wire [W-1:0] pos_diff;
    wire [W-1:0] neg_diff;
    wire [W-1:0] pos_clip;
    wire [W-1:0] neg_clip;
    wire [W-1:0] clip_result;
    reg [W-1:0] clip_reg;

    // 输入寄存器级
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            din_reg <= {W{1'b0}};
        end else begin
            din_reg <= din;
        end
    end

    // 阈值检测
    assign above_thresh = din_reg > THRESH;
    assign below_thresh = din_reg < -THRESH;

    // 条件求和减法实现
    wire [W-1:0] pos_diff_temp;
    wire [W-1:0] neg_diff_temp;
    
    // 正向差值计算
    assign pos_diff_temp = din_reg + (~THRESH + 1'b1);
    assign pos_diff = above_thresh ? pos_diff_temp : {W{1'b0}};
    
    // 负向差值计算
    assign neg_diff_temp = (~din_reg + 1'b1) + (~THRESH + 1'b1);
    assign neg_diff = below_thresh ? neg_diff_temp : {W{1'b0}};
    
    // 裁剪值计算
    assign pos_clip = THRESH + (pos_diff >> 1);
    assign neg_clip = -THRESH - (neg_diff >> 1);
    
    // 结果选择
    assign clip_result = above_thresh ? pos_clip : 
                         below_thresh ? neg_clip : din_reg;
    
    // 输出寄存器级
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            clip_reg <= {W{1'b0}};
            dout <= {W{1'b0}};
        end else begin
            clip_reg <= clip_result;
            dout <= clip_reg;
        end
    end
    
endmodule
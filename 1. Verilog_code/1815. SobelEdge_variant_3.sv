//SystemVerilog
module SobelEdge #(parameter W=8) (
    input clk,
    input rst,
    input valid_in,
    input [W-1:0] pixel_in,
    output reg valid_out,
    output reg [W+1:0] gradient
);
    // 流水线寄存器
    reg [W-1:0] window_stage1 [0:8];
    reg [W-1:0] window_stage2 [0:8];
    reg [W-1:0] window_stage3 [0:8];
    reg valid_stage1, valid_stage2, valid_stage3;
    
    // 流水线梯度计算中间结果
    reg [W+1:0] grad_x_stage1;
    reg [W+1:0] grad_x_stage2;
    reg [W+1:0] grad_x_stage3;
    reg [W+1:0] grad_y_stage1;
    reg [W+1:0] grad_y_stage2;
    reg [W+1:0] grad_y_stage3;
    
    // 绝对值中间结果
    reg [W+1:0] abs_x_stage3;
    reg [W+1:0] abs_y_stage3;
    
    integer i;
    
    // 第一级流水线 - 输入缓存和窗口移位
    always @(posedge clk) begin
        if (rst) begin
            valid_stage1 <= 1'b0;
            for(i=0; i<9; i=i+1)
                window_stage1[i] <= 0;
        end else begin
            valid_stage1 <= valid_in;
            
            if (valid_in) begin
                for(i=8; i>0; i=i-1)
                    window_stage1[i] <= window_stage1[i-1];
                window_stage1[0] <= pixel_in;
            end
        end
    end
    
    // 第二级流水线 - 梯度X计算
    always @(posedge clk) begin
        if (rst) begin
            valid_stage2 <= 1'b0;
            grad_x_stage1 <= 0;
            for(i=0; i<9; i=i+1)
                window_stage2[i] <= 0;
        end else begin
            valid_stage2 <= valid_stage1;
            
            for(i=0; i<9; i=i+1)
                window_stage2[i] <= window_stage1[i];
                
            if (valid_stage1) begin
                grad_x_stage1 <= (window_stage1[0] + (window_stage1[3] << 1) + window_stage1[6]) - 
                                (window_stage1[2] + (window_stage1[5] << 1) + window_stage1[8]);
            end
        end
    end
    
    // 第三级流水线 - 梯度Y计算和X梯度传递
    always @(posedge clk) begin
        if (rst) begin
            valid_stage3 <= 1'b0;
            grad_x_stage2 <= 0;
            grad_y_stage1 <= 0;
            for(i=0; i<9; i=i+1)
                window_stage3[i] <= 0;
        end else begin
            valid_stage3 <= valid_stage2;
            grad_x_stage2 <= grad_x_stage1;
            
            for(i=0; i<9; i=i+1)
                window_stage3[i] <= window_stage2[i];
                
            if (valid_stage2) begin
                grad_y_stage1 <= (window_stage2[0] + (window_stage2[1] << 1) + window_stage2[2]) - 
                                (window_stage2[6] + (window_stage2[7] << 1) + window_stage2[8]);
            end
        end
    end
    
    // 第四级流水线 - 绝对值计算
    always @(posedge clk) begin
        if (rst) begin
            valid_out <= 1'b0;
            grad_x_stage3 <= 0;
            grad_y_stage2 <= 0;
            abs_x_stage3 <= 0;
            abs_y_stage3 <= 0;
        end else begin
            valid_out <= valid_stage3;
            grad_x_stage3 <= grad_x_stage2;
            grad_y_stage2 <= grad_y_stage1;
            
            if (valid_stage3) begin
                abs_x_stage3 <= grad_x_stage2[W+1] ? ~grad_x_stage2 + 1'b1 : grad_x_stage2;
                abs_y_stage3 <= grad_y_stage1[W+1] ? ~grad_y_stage1 + 1'b1 : grad_y_stage1;
            end
        end
    end
    
    // 第五级流水线 - 最终梯度计算
    always @(posedge clk) begin
        if (rst) begin
            gradient <= 0;
        end else if (valid_out) begin
            gradient <= abs_x_stage3 + abs_y_stage3;
        end
    end
endmodule
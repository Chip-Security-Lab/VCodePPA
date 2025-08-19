//SystemVerilog
module MorphFilter #(parameter W=8) (
    input clk,
    input rst,
    input valid_in,
    input [W-1:0] pixel_in,
    output valid_out,
    output [W-1:0] pixel_out
);
    // 寄存器组用于存储数据流水线各阶段的窗口数据
    reg [W-1:0] window_s1 [0:8];
    reg [W-1:0] window_s2 [0:2];
    reg [W-1:0] window_s3 [0:2];
    reg [W-1:0] window_s4 [0:2];
    
    // 流水线控制信号
    reg valid_s1, valid_s2, valid_s3, valid_s4, valid_s5;
    
    // 最终输出结果
    reg [W-1:0] pixel_out_reg;
    
    integer i;
    
    // 第一级流水线：数据移位
    always @(posedge clk) begin
        if (rst) begin
            valid_s1 <= 1'b0;
            for(i=0; i<=8; i=i+1)
                window_s1[i] <= {W{1'b0}};
        end else begin
            valid_s1 <= valid_in;
            if (valid_in) begin
                // 移位窗口数据
                for(i=8; i>0; i=i-1)
                    window_s1[i] <= window_s1[i-1];
                window_s1[0] <= pixel_in;
            end
        end
    end
    
    // 第二级流水线：传递第一级处理后的顶部窗口
    always @(posedge clk) begin
        if (rst) begin
            valid_s2 <= 1'b0;
            for(i=0; i<=2; i=i+1)
                window_s2[i] <= {W{1'b0}};
        end else begin
            valid_s2 <= valid_s1;
            if (valid_s1) begin
                // 只处理窗口的顶部部分
                for(i=0; i<=2; i=i+1)
                    window_s2[i] <= window_s1[i];
            end
        end
    end
    
    // 第三级流水线：传递第一级处理后的中部窗口
    always @(posedge clk) begin
        if (rst) begin
            valid_s3 <= 1'b0;
            for(i=0; i<=2; i=i+1)
                window_s3[i] <= {W{1'b0}};
        end else begin
            valid_s3 <= valid_s2;
            if (valid_s2) begin
                // 处理窗口的中部部分
                for(i=0; i<=2; i=i+1)
                    window_s3[i] <= window_s1[i+3];
            end
        end
    end
    
    // 第四级流水线：传递第一级处理后的底部窗口
    always @(posedge clk) begin
        if (rst) begin
            valid_s4 <= 1'b0;
            for(i=0; i<=2; i=i+1)
                window_s4[i] <= {W{1'b0}};
        end else begin
            valid_s4 <= valid_s3;
            if (valid_s3) begin
                // 处理窗口的底部部分
                for(i=0; i<=2; i=i+1)
                    window_s4[i] <= window_s1[i+6];
            end
        end
    end
    
    // 第五级流水线：执行膨胀操作的第一步 - 计算中间行
    reg [W-1:0] mid_result;
    always @(posedge clk) begin
        if (rst) begin
            mid_result <= {W{1'b0}};
            valid_s5 <= 1'b0;
        end else begin
            valid_s5 <= valid_s4;
            if (valid_s4) begin
                // 中间行的计算结果
                mid_result <= window_s3[0] | window_s3[1] | window_s3[2];
            end
        end
    end
    
    // 第六级流水线：完成膨胀操作并生成输出
    always @(posedge clk) begin
        if (rst) begin
            pixel_out_reg <= {W{1'b0}};
            valid_s6 <= 1'b0;
        end else begin
            valid_s6 <= valid_s5;
            if (valid_s5) begin
                // 根据中间行的结果决定最终输出
                pixel_out_reg <= (mid_result) ? 8'hFF : 8'h00;
            end
        end
    end
    
    // 输出赋值
    assign pixel_out = pixel_out_reg;
    assign valid_out = valid_s6;
    
    // 声明流水线最后一级控制信号
    reg valid_s6;
    
endmodule
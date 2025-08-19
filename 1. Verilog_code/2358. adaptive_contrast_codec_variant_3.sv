//SystemVerilog
module adaptive_contrast_codec (
    input clk, rst_n,
    input [7:0] pixel_in,
    input [7:0] min_val, max_val,  // Current frame min/max values
    input enable, new_frame,
    output reg [7:0] pixel_out,
    output reg valid_out,          // 指示输出有效
    input ready_in                 // 上游准备好接收数据
);
    // Pipeline stage registers
    reg [7:0] pixel_stage1, pixel_stage2;
    reg [7:0] contrast_min, contrast_max;
    reg enable_stage1, enable_stage2;
    reg valid_stage1, valid_stage2;
    
    // 计算中间值
    wire [8:0] range = contrast_max - contrast_min;
    wire [8:0] pixel_diff_stage1 = (pixel_stage1 > contrast_min) ? 
                                  (pixel_stage1 - contrast_min) : 9'd0;
    reg [8:0] pixel_diff_stage2;
    
    // 计算缩放值
    wire [16:0] scaled_value = (pixel_diff_stage2 * 255) / 
                              ((range == 0) ? 8'd1 : range);
    
    // 流水线控制
    wire pipeline_ready = ready_in || !valid_out;
    wire pipeline_enable = pipeline_ready && !new_frame;
    
    //----------------------------------------------
    // 对比度范围更新 - 仅在新帧时进行
    //----------------------------------------------
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            contrast_min <= 8'd0;
            contrast_max <= 8'd255;
        end else if (new_frame) begin
            contrast_min <= min_val;
            contrast_max <= max_val;
        end
    end
    
    //----------------------------------------------
    // 第一级流水线：存储输入和预处理 - 信号捕获
    //----------------------------------------------
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            valid_stage1 <= 1'b0;
        end else if (pipeline_enable) begin
            valid_stage1 <= 1'b1;
        end
    end
    
    //----------------------------------------------
    // 第一级流水线：存储输入数据
    //----------------------------------------------
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            pixel_stage1 <= 8'd0;
        end else if (pipeline_enable) begin
            pixel_stage1 <= pixel_in;
        end
    end
    
    //----------------------------------------------
    // 第一级流水线：存储使能控制信号
    //----------------------------------------------
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            enable_stage1 <= 1'b0;
        end else if (pipeline_enable) begin
            enable_stage1 <= enable;
        end
    end
    
    //----------------------------------------------
    // 第二级流水线：传递有效控制信号
    //----------------------------------------------
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            valid_stage2 <= 1'b0;
        end else if (pipeline_enable) begin
            valid_stage2 <= valid_stage1;
        end
    end
    
    //----------------------------------------------
    // 第二级流水线：传递像素数据
    //----------------------------------------------
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            pixel_stage2 <= 8'd0;
        end else if (pipeline_enable) begin
            pixel_stage2 <= pixel_stage1;
        end
    end
    
    //----------------------------------------------
    // 第二级流水线：计算差值
    //----------------------------------------------
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            pixel_diff_stage2 <= 9'd0;
        end else if (pipeline_enable) begin
            pixel_diff_stage2 <= pixel_diff_stage1;
        end
    end
    
    //----------------------------------------------
    // 第二级流水线：传递使能控制信号
    //----------------------------------------------
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            enable_stage2 <= 1'b0;
        end else if (pipeline_enable) begin
            enable_stage2 <= enable_stage1;
        end
    end
    
    //----------------------------------------------
    // 第三级流水线：输出处理
    //----------------------------------------------
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            valid_out <= 1'b0;
        end else if (pipeline_enable) begin
            valid_out <= valid_stage2;
        end
    end
    
    //----------------------------------------------
    // 第三级流水线：像素值计算与输出
    //----------------------------------------------
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            pixel_out <= 8'd0;
        end else if (pipeline_enable) begin
            if (enable_stage2 && valid_stage2) begin
                pixel_out <= (scaled_value > 255) ? 8'd255 : scaled_value[7:0];
            end else if (valid_stage2) begin
                pixel_out <= pixel_stage2;
            end
        end
    end
endmodule
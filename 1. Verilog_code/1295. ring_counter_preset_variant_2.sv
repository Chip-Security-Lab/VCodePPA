//SystemVerilog
module ring_counter_preset (
    input wire clk,
    input wire reset_n,
    input wire load,
    input wire in_valid,
    input wire [3:0] preset_val,
    output wire [3:0] out,
    output wire out_valid
);

    // 流水线寄存器
    reg [3:0] stage1_data, stage2_data, stage3_data;
    reg stage1_valid, stage2_valid, stage3_valid;
    
    // 时钟缓冲器以减少扇出负载
    wire clk_buf1, clk_buf2, clk_buf3;
    
    // 输出缓冲寄存器
    reg [3:0] out_buf1, out_buf2;
    reg out_valid_buf;
    
    // 阶段1数据缓冲器，减少stage1_data的扇出负载
    reg [3:0] stage1_data_buf;
    
    // 流水线控制信号
    reg [3:0] next_value;
    
    // 分配时钟缓冲
    assign clk_buf1 = clk;  // 用于第一级流水线
    assign clk_buf2 = clk;  // 用于第二级流水线
    assign clk_buf3 = clk;  // 用于第三级流水线和输出缓冲
    
    // 位缓冲器，减少b0的扇出负载
    wire b0, b0_buf1, b0_buf2;
    assign b0 = stage1_data[0];
    assign b0_buf1 = b0;
    assign b0_buf2 = b0;
    
    // 第一级流水线 - 确定下一个值
    always @(posedge clk_buf1 or negedge reset_n) begin
        if (!reset_n) begin
            stage1_data <= 4'b0001;
            stage1_valid <= 1'b0;
        end else begin
            if (in_valid) begin
                stage1_data <= load ? preset_val : {out_buf1[0], out_buf1[3:1]};
                stage1_valid <= 1'b1;
            end else if (stage1_valid) begin
                stage1_data <= load ? preset_val : {b0_buf1, stage1_data[3:1]};
            end else begin
                stage1_valid <= 1'b0;
            end
        end
    end
    
    // stage1_data缓冲器，减少扇出负载
    always @(posedge clk_buf1 or negedge reset_n) begin
        if (!reset_n) begin
            stage1_data_buf <= 4'b0001;
        end else begin
            stage1_data_buf <= stage1_data;
        end
    end
    
    // 第二级流水线 - 中间处理
    always @(posedge clk_buf2 or negedge reset_n) begin
        if (!reset_n) begin
            stage2_data <= 4'b0001;
            stage2_valid <= 1'b0;
        end else begin
            stage2_data <= stage1_data_buf;
            stage2_valid <= stage1_valid;
        end
    end
    
    // 第三级流水线 - 最终输出
    always @(posedge clk_buf3 or negedge reset_n) begin
        if (!reset_n) begin
            stage3_data <= 4'b0001;
            stage3_valid <= 1'b0;
        end else begin
            stage3_data <= stage2_data;
            stage3_valid <= stage2_valid;
        end
    end
    
    // 输出缓冲寄存器 - 减少out信号的扇出负载
    always @(posedge clk_buf3 or negedge reset_n) begin
        if (!reset_n) begin
            out_buf1 <= 4'b0001;
            out_buf2 <= 4'b0001;
            out_valid_buf <= 1'b0;
        end else begin
            out_buf1 <= stage3_data;
            out_buf2 <= out_buf1;
            out_valid_buf <= stage3_valid;
        end
    end
    
    // 输出赋值
    assign out = out_buf2;
    assign out_valid = out_valid_buf;

endmodule
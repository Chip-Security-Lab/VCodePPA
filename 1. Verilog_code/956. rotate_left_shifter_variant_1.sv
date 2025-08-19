//SystemVerilog
module rotate_left_shifter (
    input clk, rst, enable,
    input start,                  // 启动信号
    output valid_out,             // 输出有效信号
    output reg [7:0] data_out
);
    // 流水线寄存器和控制信号
    reg [7:0] data_stage1, data_stage2;
    reg valid_stage1, valid_stage2, valid_stage3;
    
    // 初始化
    initial begin
        data_out = 8'b10101010;
        data_stage1 = 8'b10101010;
        data_stage2 = 8'b10101010;
        valid_stage1 = 1'b0;
        valid_stage2 = 1'b0;
        valid_stage3 = 1'b0;
    end
    
    // 第一级流水线 - 数据装载阶段
    always @(posedge clk) begin
        if (rst) begin
            data_stage1 <= 8'b10101010;
            valid_stage1 <= 1'b0;
        end else if (enable) begin
            if (start) begin
                data_stage1 <= 8'b10101010; // 使用初始模式
                valid_stage1 <= 1'b1;
            end else if (valid_stage3) begin
                // 使用最终输出进行循环移位
                data_stage1 <= {data_out[6:0], data_out[7]};
                valid_stage1 <= 1'b1;
            end else begin
                valid_stage1 <= 1'b0;
            end
        end
    end
    
    // 第二级流水线 - 中间处理阶段
    always @(posedge clk) begin
        if (rst) begin
            data_stage2 <= 8'b0;
            valid_stage2 <= 1'b0;
        end else if (enable) begin
            data_stage2 <= data_stage1;
            valid_stage2 <= valid_stage1;
        end
    end
    
    // 第三级流水线 - 输出阶段
    always @(posedge clk) begin
        if (rst) begin
            data_out <= 8'b0;
            valid_stage3 <= 1'b0;
        end else if (enable) begin
            data_out <= data_stage2;
            valid_stage3 <= valid_stage2;
        end
    end
    
    // 输出有效信号
    assign valid_out = valid_stage3;
    
endmodule
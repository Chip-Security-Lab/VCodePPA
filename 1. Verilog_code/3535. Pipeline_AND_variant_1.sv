//SystemVerilog
module Pipeline_AND(
    input clk,
    input rst_n,                  // 复位信号
    input valid_in,               // 输入有效信号
    input [15:0] din_a, din_b,
    output reg [15:0] dout,
    output reg valid_out          // 输出有效信号
);
    // 将16位AND操作分成4级流水线，每级处理4位
    
    // 第一阶段信号
    reg [3:0] stage1_a_0, stage1_a_1, stage1_a_2, stage1_a_3;
    reg [3:0] stage1_b_0, stage1_b_1, stage1_b_2, stage1_b_3;
    reg stage1_valid;
    
    // 第二阶段信号
    reg [3:0] stage2_and_0, stage2_and_1, stage2_and_2, stage2_and_3;
    reg stage2_valid;
    
    // 第三阶段信号
    reg [7:0] stage3_result_lo, stage3_result_hi;
    reg stage3_valid;
    
    // 阶段1-A: 处理第一阶段输入A数据分割
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            stage1_a_0 <= 4'b0;
            stage1_a_1 <= 4'b0;
            stage1_a_2 <= 4'b0;
            stage1_a_3 <= 4'b0;
        end else if (valid_in) begin
            stage1_a_0 <= din_a[3:0];
            stage1_a_1 <= din_a[7:4];
            stage1_a_2 <= din_a[11:8];
            stage1_a_3 <= din_a[15:12];
        end
    end
    
    // 阶段1-B: 处理第一阶段输入B数据分割
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            stage1_b_0 <= 4'b0;
            stage1_b_1 <= 4'b0;
            stage1_b_2 <= 4'b0;
            stage1_b_3 <= 4'b0;
        end else if (valid_in) begin
            stage1_b_0 <= din_b[3:0];
            stage1_b_1 <= din_b[7:4];
            stage1_b_2 <= din_b[11:8];
            stage1_b_3 <= din_b[15:12];
        end
    end
    
    // 阶段1-C: 处理第一阶段有效信号传递
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            stage1_valid <= 1'b0;
        end else begin
            stage1_valid <= valid_in;
        end
    end
    
    // 阶段2-A: 处理低8位AND操作
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            stage2_and_0 <= 4'b0;
            stage2_and_1 <= 4'b0;
        end else if (stage1_valid) begin
            stage2_and_0 <= stage1_a_0 & stage1_b_0;
            stage2_and_1 <= stage1_a_1 & stage1_b_1;
        end
    end
    
    // 阶段2-B: 处理高8位AND操作
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            stage2_and_2 <= 4'b0;
            stage2_and_3 <= 4'b0;
        end else if (stage1_valid) begin
            stage2_and_2 <= stage1_a_2 & stage1_b_2;
            stage2_and_3 <= stage1_a_3 & stage1_b_3;
        end
    end
    
    // 阶段2-C: 处理第二阶段有效信号传递
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            stage2_valid <= 1'b0;
        end else begin
            stage2_valid <= stage1_valid;
        end
    end
    
    // 阶段3-A: 合并低8位结果
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            stage3_result_lo <= 8'b0;
        end else if (stage2_valid) begin
            stage3_result_lo <= {stage2_and_1, stage2_and_0};
        end
    end
    
    // 阶段3-B: 合并高8位结果
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            stage3_result_hi <= 8'b0;
        end else if (stage2_valid) begin
            stage3_result_hi <= {stage2_and_3, stage2_and_2};
        end
    end
    
    // 阶段3-C: 处理第三阶段有效信号传递
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            stage3_valid <= 1'b0;
        end else begin
            stage3_valid <= stage2_valid;
        end
    end
    
    // 阶段4-A: 处理最终数据输出
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            dout <= 16'b0;
        end else if (stage3_valid) begin
            dout <= {stage3_result_hi, stage3_result_lo};
        end
    end
    
    // 阶段4-B: 处理输出有效信号
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            valid_out <= 1'b0;
        end else begin
            valid_out <= stage3_valid;
        end
    end
    
endmodule
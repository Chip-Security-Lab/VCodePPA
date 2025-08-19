//SystemVerilog
module hamming_error_stats(
    input clk, rst,
    input [6:0] code_in,
    input valid_in,                  // 输入数据有效信号
    output reg valid_out,            // 输出数据有效信号
    output reg [3:0] data_out,
    output reg error_detected,
    output reg [7:0] total_errors,
    output reg [7:0] corrected_errors
);
    // Stage 1 - 计算syndrome
    reg [6:0] code_stage1;
    reg [2:0] syndrome_stage1;
    reg valid_stage1;

    // Stage 2 - 处理错误检测和纠正
    reg [6:0] code_stage2;
    reg [2:0] syndrome_stage2;
    reg valid_stage2;
    reg error_detected_stage2;
    
    // 流水线阶段1: 计算syndrome
    always @(posedge clk or posedge rst) begin
        if (rst) begin
            code_stage1 <= 7'b0;
            syndrome_stage1 <= 3'b0;
            valid_stage1 <= 1'b0;
        end else begin
            valid_stage1 <= valid_in;
            code_stage1 <= code_in;
            
            // 计算syndrome
            syndrome_stage1[0] <= code_in[0] ^ code_in[2] ^ code_in[4] ^ code_in[6];
            syndrome_stage1[1] <= code_in[1] ^ code_in[2] ^ code_in[5] ^ code_in[6];
            syndrome_stage1[2] <= code_in[3] ^ code_in[4] ^ code_in[5] ^ code_in[6];
        end
    end
    
    // 流水线阶段2: 错误检测和计数
    always @(posedge clk or posedge rst) begin
        if (rst) begin
            code_stage2 <= 7'b0;
            syndrome_stage2 <= 3'b0;
            error_detected_stage2 <= 1'b0;
            valid_stage2 <= 1'b0;
        end else begin
            valid_stage2 <= valid_stage1;
            code_stage2 <= code_stage1;
            syndrome_stage2 <= syndrome_stage1;
            
            // 错误检测
            error_detected_stage2 <= |syndrome_stage1;
        end
    end
    
    // 流水线阶段3: 错误计数和输出生成
    always @(posedge clk or posedge rst) begin
        if (rst) begin
            data_out <= 4'b0;
            error_detected <= 1'b0;
            total_errors <= 8'b0;
            corrected_errors <= 8'b0;
            valid_out <= 1'b0;
        end else begin
            valid_out <= valid_stage2;
            error_detected <= error_detected_stage2;
            
            // 生成输出数据
            data_out <= {code_stage2[6], code_stage2[5], code_stage2[4], code_stage2[2]};
            
            // 更新错误计数器 (只有在数据有效时)
            if (valid_stage2) begin
                if (error_detected_stage2) begin
                    total_errors <= total_errors + 1;
                    if (syndrome_stage2 != 3'b0) begin
                        corrected_errors <= corrected_errors + 1;
                    end
                end
            end
        end
    end
endmodule
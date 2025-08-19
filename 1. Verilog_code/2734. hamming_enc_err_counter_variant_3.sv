//SystemVerilog
module hamming_enc_err_counter(
    input clk, rst, en,
    input [3:0] data_in,
    input error_inject,
    output reg [6:0] encoded,
    output reg [7:0] error_count
);
    // 流水线寄存器 - 第一级
    reg [3:0] data_stage1;
    reg error_inject_stage1;
    reg valid_stage1;
    
    // 流水线寄存器 - 第二级
    reg [6:0] encoded_stage2;
    reg error_inject_stage2;
    reg valid_stage2;
    
    // 中间计算结果
    wire [6:0] encoded_calc;
    
    // 第一级流水线 - 输入寄存
    always @(posedge clk or posedge rst) begin
        if (rst) begin
            data_stage1 <= 4'b0;
            error_inject_stage1 <= 1'b0;
            valid_stage1 <= 1'b0;
        end else if (en) begin
            data_stage1 <= data_in;
            error_inject_stage1 <= error_inject;
            valid_stage1 <= 1'b1;
        end else begin
            valid_stage1 <= 1'b0;
        end
    end
    
    // 哈明编码计算
    assign encoded_calc[0] = data_stage1[0] ^ data_stage1[1] ^ data_stage1[3];
    assign encoded_calc[1] = data_stage1[0] ^ data_stage1[2] ^ data_stage1[3];
    assign encoded_calc[2] = data_stage1[0];
    assign encoded_calc[3] = data_stage1[1] ^ data_stage1[2] ^ data_stage1[3];
    assign encoded_calc[4] = data_stage1[1];
    assign encoded_calc[5] = data_stage1[2];
    assign encoded_calc[6] = data_stage1[3];
    
    // 第二级流水线 - 编码计算结果寄存
    always @(posedge clk or posedge rst) begin
        if (rst) begin
            encoded_stage2 <= 7'b0;
            error_inject_stage2 <= 1'b0;
            valid_stage2 <= 1'b0;
        end else if (valid_stage1) begin
            encoded_stage2 <= error_inject_stage1 ? 
                              {encoded_calc[6:1], ~encoded_calc[0]} : 
                              encoded_calc;
            error_inject_stage2 <= error_inject_stage1;
            valid_stage2 <= valid_stage1;
        end else begin
            valid_stage2 <= 1'b0;
        end
    end
    
    // 最终输出和错误计数
    always @(posedge clk or posedge rst) begin
        if (rst) begin
            encoded <= 7'b0;
            error_count <= 8'b0;
        end else if (valid_stage2) begin
            encoded <= encoded_stage2;
            if (error_inject_stage2) begin
                error_count <= error_count + 1;
            end
        end
    end
endmodule
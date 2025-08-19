//SystemVerilog
module hamming_recovery (
    input wire clk,
    input wire [11:0] encoded,
    output reg [7:0] decoded,
    output reg error_detected,
    output reg error_corrected
);
    // 为高扇出信号添加缓冲寄存器
    reg [11:0] encoded_buf1, encoded_buf2;
    
    // 对encoded信号添加缓冲寄存器，分散负载
    always @(posedge clk) begin
        encoded_buf1 <= encoded;
        encoded_buf2 <= encoded;
    end
    
    // 分段计算syndrome，减少单一计算路径的复杂度
    wire syndrome0_part1, syndrome0_part2;
    wire syndrome1_part1, syndrome1_part2;
    wire syndrome2_part1, syndrome2_part2;
    wire syndrome3_part1, syndrome3_part2;
    
    assign syndrome0_part1 = encoded_buf1[0] ^ encoded_buf1[2] ^ encoded_buf1[4];
    assign syndrome0_part2 = encoded_buf1[6] ^ encoded_buf1[8] ^ encoded_buf1[10];
    
    assign syndrome1_part1 = encoded_buf1[1] ^ encoded_buf1[2] ^ encoded_buf1[5];
    assign syndrome1_part2 = encoded_buf1[6] ^ encoded_buf1[9] ^ encoded_buf1[10];
    
    assign syndrome2_part1 = encoded_buf1[3] ^ encoded_buf1[4] ^ encoded_buf1[5];
    assign syndrome2_part2 = encoded_buf1[6] ^ encoded_buf1[11];
    
    assign syndrome3_part1 = encoded_buf1[7] ^ encoded_buf1[8] ^ encoded_buf1[9];
    assign syndrome3_part2 = encoded_buf1[10] ^ encoded_buf1[11];
    
    reg [3:0] syndrome;
    reg [3:0] syndrome_buf;
    
    // 计算syndrome，使用分段计算结果
    always @(posedge clk) begin
        syndrome[0] <= syndrome0_part1 ^ syndrome0_part2;
        syndrome[1] <= syndrome1_part1 ^ syndrome1_part2;
        syndrome[2] <= syndrome2_part1 ^ syndrome2_part2;
        syndrome[3] <= syndrome3_part1 ^ syndrome3_part2;
        syndrome_buf <= syndrome; // 为syndrome添加缓冲寄存器
    end
    
    // 错误检测逻辑
    always @(posedge clk) begin
        error_detected <= (syndrome != 4'b0000);
    end
    
    reg [11:0] corrected;
    reg [11:0] corrected_buf;
    
    // 错误纠正逻辑，使用缓冲的syndrome
    always @(posedge clk) begin
        if (syndrome_buf != 4'b0000) begin
            if (syndrome_buf <= 12) begin
                corrected <= encoded_buf2;
                corrected[syndrome_buf-1] <= ~encoded_buf2[syndrome_buf-1];
                error_corrected <= 1'b1;
            end else begin
                corrected <= encoded_buf2;
                error_corrected <= 1'b0;
            end
        end else begin
            corrected <= encoded_buf2;
            error_corrected <= 1'b0;
        end
        
        // 为corrected添加缓冲寄存器
        corrected_buf <= corrected;
    end
    
    // 数据提取，使用缓冲的corrected数据
    always @(posedge clk) begin
        decoded <= {corrected_buf[11], corrected_buf[10], corrected_buf[9], corrected_buf[8], 
                   corrected_buf[6], corrected_buf[5], corrected_buf[4], corrected_buf[2]};
    end
endmodule
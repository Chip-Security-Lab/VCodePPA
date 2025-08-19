//SystemVerilog
module priority_parity_checker (
    input         clk,
    input         rst_n,
    input  [15:0] data,
    output [3:0]  parity,
    output        error
);

    reg  [7:0] low_byte_r1;
    reg  [7:0] high_byte_r1;
    reg        byte_parity_r1;
    reg  [3:0] parity_r2;
    reg        error_r2;
    reg  [3:0] priority_encoder;

    // 第一级流水线 - 数据预处理
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            low_byte_r1   <= 8'h0;
            high_byte_r1  <= 8'h0;
            byte_parity_r1 <= 1'b0;
        end else begin
            low_byte_r1   <= data[7:0];
            high_byte_r1  <= data[15:8];
            byte_parity_r1 <= ^data[7:0] ^ ^data[15:8];
        end
    end

    // 优先级编码器逻辑
    always @(*) begin
        priority_encoder = 4'h0;
        if (low_byte_r1[0]) priority_encoder = 4'h1;
        else if (low_byte_r1[1]) priority_encoder = 4'h2;
        else if (low_byte_r1[2]) priority_encoder = 4'h4;
        else if (low_byte_r1[3]) priority_encoder = 4'h8;
        else if (low_byte_r1[4]) priority_encoder = 4'h1;
        else if (low_byte_r1[5]) priority_encoder = 4'h2;
        else if (low_byte_r1[6]) priority_encoder = 4'h4;
        else if (low_byte_r1[7]) priority_encoder = 4'h8;
    end

    // 第二级流水线 - 错误检测和输出
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            parity_r2 <= 4'h0;
            error_r2  <= 1'b0;
        end else begin
            if (byte_parity_r1 && (low_byte_r1 != 0)) begin
                parity_r2 <= priority_encoder;
                error_r2  <= 1'b1;
            end else begin
                parity_r2 <= 4'h0;
                error_r2  <= 1'b0;
            end
        end
    end

    assign parity = parity_r2;
    assign error = error_r2;

endmodule
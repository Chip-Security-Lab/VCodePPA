//SystemVerilog
module crossbar_sync_4x4 (
    input wire clk, rst_n,
    input wire [7:0] in0, in1, in2, in3,
    input wire [1:0] sel0, sel1, sel2, sel3,
    output reg [7:0] out0, out1, out2, out3
);

    // 高扇出信号的缓冲寄存器
    reg [7:0] in0_buf1, in0_buf2;
    reg [7:0] in1_buf1, in1_buf2;
    reg [7:0] in2_buf1, in2_buf2;
    reg [7:0] in3_buf1, in3_buf2;
    reg [1:0] sel0_buf1, sel0_buf2;
    reg [1:0] sel1_buf, sel2_buf, sel3_buf;
    
    // 输入缓冲寄存器，减少输入信号的扇出负载
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            in0_buf1 <= 8'b0;
            in0_buf2 <= 8'b0;
            in1_buf1 <= 8'b0;
            in1_buf2 <= 8'b0;
            in2_buf1 <= 8'b0;
            in2_buf2 <= 8'b0;
            in3_buf1 <= 8'b0;
            in3_buf2 <= 8'b0;
            sel0_buf1 <= 2'b0;
            sel0_buf2 <= 2'b0;
            sel1_buf <= 2'b0;
            sel2_buf <= 2'b0;
            sel3_buf <= 2'b0;
        end else begin
            // 将输入信号分别缓存到两个缓冲寄存器，降低每个寄存器的扇出
            in0_buf1 <= in0;
            in0_buf2 <= in0;
            in1_buf1 <= in1;
            in1_buf2 <= in1;
            in2_buf1 <= in2;
            in2_buf2 <= in2;
            in3_buf1 <= in3;
            in3_buf2 <= in3;
            sel0_buf1 <= sel0;
            sel0_buf2 <= sel0;
            sel1_buf <= sel1;
            sel2_buf <= sel2;
            sel3_buf <= sel3;
        end
    end

    // 输出多路复用逻辑，使用缓冲寄存器代替原始输入
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            {out0, out1, out2, out3} <= 32'b0;
        end else begin
            // 输出0的多路复用器，使用if-else结构替代条件运算符
            if (sel0_buf1 == 2'b00) begin
                out0 <= in0_buf1;
            end else if (sel0_buf1 == 2'b01) begin
                out0 <= in1_buf1;
            end else if (sel0_buf1 == 2'b10) begin
                out0 <= in2_buf1;
            end else begin
                out0 <= in3_buf1;
            end
            
            // 输出1的多路复用器，使用if-else结构替代条件运算符
            if (sel1_buf == 2'b00) begin
                out1 <= in0_buf1;
            end else if (sel1_buf == 2'b01) begin
                out1 <= in1_buf1;
            end else if (sel1_buf == 2'b10) begin
                out1 <= in2_buf1;
            end else begin
                out1 <= in3_buf1;
            end
            
            // 输出2的多路复用器，使用if-else结构替代条件运算符
            if (sel2_buf == 2'b00) begin
                out2 <= in0_buf2;
            end else if (sel2_buf == 2'b01) begin
                out2 <= in1_buf2;
            end else if (sel2_buf == 2'b10) begin
                out2 <= in2_buf2;
            end else begin
                out2 <= in3_buf2;
            end
            
            // 输出3的多路复用器，使用if-else结构替代条件运算符
            if (sel3_buf == 2'b00) begin
                out3 <= in0_buf2;
            end else if (sel3_buf == 2'b01) begin
                out3 <= in1_buf2;
            end else if (sel3_buf == 2'b10) begin
                out3 <= in2_buf2;
            end else begin
                out3 <= in3_buf2;
            end
        end
    end
endmodule
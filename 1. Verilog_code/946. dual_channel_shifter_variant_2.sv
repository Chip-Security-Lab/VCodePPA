//SystemVerilog
module dual_channel_shifter (
    input clk,
    input rst_n,
    
    // 输入数据接口 - Valid-Ready握手
    input [15:0] ch1_data, ch2_data,
    input [3:0] shift_value,
    input data_valid,
    output reg data_ready,
    
    // 输出数据接口 - Valid-Ready握手
    output reg [15:0] out1_data, out2_data,
    output reg out_valid,
    input out_ready
);

    // 内部寄存器
    reg [15:0] ch1_reg, ch2_reg;
    reg [3:0] shift_reg;
    reg processing;
    
    // 输入握手逻辑
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            data_ready <= 1'b1;
            processing <= 1'b0;
            ch1_reg <= 16'h0000;
            ch2_reg <= 16'h0000;
            shift_reg <= 4'h0;
        end
        else begin
            if (data_valid && data_ready) begin
                // 捕获输入数据
                ch1_reg <= ch1_data;
                ch2_reg <= ch2_data;
                shift_reg <= shift_value;
                processing <= 1'b1;
                data_ready <= 1'b0;
            end
            else if (out_valid && out_ready) begin
                // 数据已被接收，准备接收新数据
                processing <= 1'b0;
                data_ready <= 1'b1;
            end
        end
    end
    
    // 处理和输出逻辑
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            out1_data <= 16'h0000;
            out2_data <= 16'h0000;
            out_valid <= 1'b0;
        end
        else begin
            if (processing && !out_valid) begin
                // 执行数据处理
                out1_data <= (ch1_reg << shift_reg) | (ch1_reg >> (16 - shift_reg));
                out2_data <= (ch2_reg >> shift_reg) | (ch2_reg << (16 - shift_reg));
                out_valid <= 1'b1;
            end
            else if (out_valid && out_ready) begin
                // 输出已被接收
                out_valid <= 1'b0;
            end
        end
    end

endmodule
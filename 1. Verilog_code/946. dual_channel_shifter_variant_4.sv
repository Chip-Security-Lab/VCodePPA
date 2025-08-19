//SystemVerilog
module dual_channel_shifter (
    input clk,
    input rst_n,
    // Valid-Ready 输入接口
    input [15:0] ch1, ch2,
    input [3:0] shift,
    input valid_in,
    output reg ready_in,
    // Valid-Ready 输出接口
    output reg [15:0] out1, out2,
    output reg valid_out,
    input ready_out
);

    // 内部寄存器
    reg [15:0] ch1_reg, ch2_reg;
    reg [3:0] shift_reg;
    reg data_valid;
    
    // 输入握手逻辑
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            ready_in <= 1'b1;
            data_valid <= 1'b0;
            ch1_reg <= 16'd0;
            ch2_reg <= 16'd0;
            shift_reg <= 4'd0;
        end else begin
            if (valid_in && ready_in) begin
                ch1_reg <= ch1;
                ch2_reg <= ch2;
                shift_reg <= shift;
                data_valid <= 1'b1;
                ready_in <= 1'b0;  // 输入数据已接收，暂时不接收新数据
            end else if (valid_out && ready_out) begin
                // 输出数据被接收，可以接收新数据
                data_valid <= 1'b0;
                ready_in <= 1'b1;
            end
        end
    end
    
    // 输出逻辑
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            out1 <= 16'd0;
            out2 <= 16'd0;
            valid_out <= 1'b0;
        end else begin
            if (data_valid && !valid_out) begin
                // 新数据已准备好但尚未输出
                out1 <= (ch1_reg << shift_reg) | (ch1_reg >> (16 - shift_reg));
                out2 <= (ch2_reg >> shift_reg) | (ch2_reg << (16 - shift_reg));
                valid_out <= 1'b1;
            end else if (valid_out && ready_out) begin
                // 输出数据被接收
                valid_out <= 1'b0;
            end
        end
    end

endmodule
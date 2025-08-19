//SystemVerilog
module DCT_Compress (
    input clk,
    input rst_n,
    // Valid-Ready 输入接口
    input [7:0] data_in,
    input valid_in,
    output reg ready_in,
    // Valid-Ready 输出接口
    output reg [7:0] data_out,
    output reg valid_out,
    input ready_out
);

    reg signed [15:0] sum;
    reg [7:0] data_in_reg;
    reg processing;
    
    // 输入握手处理
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            ready_in <= 1'b1;
            processing <= 1'b0;
            data_in_reg <= 8'd0;
        end else begin
            if (valid_in && ready_in) begin
                // 接收数据并开始处理
                data_in_reg <= data_in;
                ready_in <= 1'b0;
                processing <= 1'b1;
            end else if (valid_out && ready_out) begin
                // 输出数据被接收，可以接收新数据
                ready_in <= 1'b1;
                processing <= 1'b0;
            end
        end
    end

    // 数据处理逻辑
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            sum <= 16'd0;
            valid_out <= 1'b0;
            data_out <= 8'd0;
        end else begin
            if (processing && !valid_out) begin
                // 执行DCT计算
                sum <= data_in_reg * 16'sd23170;  // cos(π/4) * 32768
                data_out <= (sum >>> 15) + 8'd128;
                valid_out <= 1'b1;
            end else if (valid_out && ready_out) begin
                // 输出数据被接收，重置valid信号
                valid_out <= 1'b0;
            end
        end
    end

endmodule
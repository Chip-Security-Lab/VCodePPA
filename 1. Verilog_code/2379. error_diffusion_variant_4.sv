//SystemVerilog
module error_diffusion (
    input  wire        clk,
    input  wire        rst_n,         // 复位信号，低电平有效
    input  wire [7:0]  in_data,       // 输入数据
    input  wire        in_valid,      // 输入有效信号
    output wire        in_ready,      // 输入就绪信号
    output wire [3:0]  out_data,      // 输出数据
    output reg         out_valid,     // 输出有效信号
    input  wire        out_ready      // 输出就绪信号
);

    // 内部信号
    reg [11:0] err;
    reg [11:0] sum;
    reg [3:0]  out_reg;
    reg        processing;
    wire [11:0] quantization_error;

    // 优化后的计算逻辑
    assign out_data = out_reg;
    assign in_ready = !processing || (out_valid && out_ready);
    assign quantization_error = {8'b0, sum[7:0]};

    // 状态处理和计算
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            err <= 12'd0;
            sum <= 12'd0;
            out_reg <= 4'd0;
            out_valid <= 1'b0;
            processing <= 1'b0;
        end else begin
            if (in_valid && in_ready) begin
                // 新数据输入处理
                sum <= {4'b0, in_data} + err;
                processing <= 1'b1;
                out_valid <= 1'b0;
            end else if (processing && !out_valid) begin
                // 计算完成，准备输出
                out_reg <= sum[11:8];
                err <= quantization_error;
                out_valid <= 1'b1;
            end else if (out_valid && out_ready) begin
                // 数据已被接收
                out_valid <= 1'b0;
                processing <= 1'b0;
            end
        end
    end

endmodule
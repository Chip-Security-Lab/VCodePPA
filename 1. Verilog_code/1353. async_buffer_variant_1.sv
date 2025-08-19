//SystemVerilog
module async_buffer (
    input  wire        clk,           // 时钟信号
    input  wire        rst_n,         // 低电平有效复位信号
    input  wire [15:0] data_in,       // 输入数据
    input  wire        enable,        // 使能信号
    output reg  [15:0] data_out       // 输出数据
);

    // 组合逻辑计算结果
    wire [15:0] processed_data;
    assign processed_data = enable ? data_in : 16'b0;
    
    // 单级流水线 - 直接捕获处理后的数据
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            data_out <= 16'b0;
        end else begin
            data_out <= processed_data;
        end
    end

endmodule
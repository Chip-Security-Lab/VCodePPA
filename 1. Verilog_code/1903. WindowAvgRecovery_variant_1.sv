//SystemVerilog
module WindowAvgRecovery #(parameter WIDTH=8, DEPTH=4) (
    input clk, rst_n,
    input [WIDTH-1:0] din,
    output reg [WIDTH-1:0] dout
);
    reg [WIDTH-1:0] buffer [0:DEPTH-1];
    reg [WIDTH-1:0] sum_stage; // 中间寄存器存储求和结果
    integer i;

    // 管理buffer移位寄存器更新
    always @(posedge clk) begin
        if (!rst_n) begin
            for (i = 0; i < DEPTH; i = i + 1) begin
                buffer[i] <= 0;
            end
        end else begin
            for (i = DEPTH-1; i > 0; i = i - 1) begin
                buffer[i] <= buffer[i-1];
            end
            buffer[0] <= din;
        end
    end

    // 计算求和阶段
    always @(posedge clk) begin
        if (!rst_n) begin
            sum_stage <= 0;
        end else begin
            sum_stage <= buffer[0] + buffer[1] + buffer[2] + buffer[3];
        end
    end

    // 计算最终的平均值输出
    always @(posedge clk) begin
        if (!rst_n) begin
            dout <= 0;
        end else begin
            dout <= sum_stage >> 2;
        end
    end
endmodule
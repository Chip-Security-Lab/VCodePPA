//SystemVerilog
module mul_add (
    input clk,
    input rst_n,
    input [3:0] num1,
    input [3:0] num2,
    input req,
    output reg [7:0] product,
    output reg [4:0] sum,
    output reg ack
);

    reg [3:0] num1_reg, num2_reg;
    reg busy;

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            num1_reg <= 4'b0;
            num2_reg <= 4'b0;
            product <= 8'b0;
            sum <= 5'b0;
            ack <= 1'b0;
            busy <= 1'b0;
        end else begin
            if (req && !busy && !ack) begin
                // 捕获输入数据并开始计算
                num1_reg <= num1;
                num2_reg <= num2;
                busy <= 1'b1;
                ack <= 1'b0;
            end else if (busy) begin
                // 完成计算并设置输出
                product <= num1_reg * num2_reg;
                sum <= num1_reg + num2_reg;
                ack <= 1'b1;
                busy <= 1'b0;
            end else if (ack && !req) begin
                // 复位应答信号，等待下一个请求
                ack <= 1'b0;
            end
        end
    end

endmodule
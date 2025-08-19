//SystemVerilog
module DivRem(
    input [7:0] num, den,
    output [7:0] q, r
);
    wire [7:0] quotient, remainder;
    wire div_by_zero;

    SRTDivider srt_div_inst(
        .dividend(num),
        .divisor(den),
        .quotient(quotient),
        .remainder(remainder),
        .div_by_zero(div_by_zero)
    );

    // 除零保护
    assign q = div_by_zero ? 8'hFF : quotient;
    assign r = div_by_zero ? num : remainder;
endmodule

module SRTDivider(
    input [7:0] dividend,
    input [7:0] divisor,
    output reg [7:0] quotient,
    output reg [7:0] remainder,
    output div_by_zero
);
    // 除零检测
    assign div_by_zero = (divisor == 8'b0);

    reg [7:0] Q, M;
    reg [8:0] A;
    reg [3:0] count;

    // 初始化计算寄存器
    always @(*) begin
        Q = 8'b0;
        A = 9'b0;
        M = divisor;
        count = 4'd8;
    end

    // SRT除法算法实现
    always @(*) begin
        if (!div_by_zero) begin
            // 将被除数放入A寄存器
            A[7:0] = dividend;

            // 执行8次迭代
            repeat (8) begin
                // 左移A和Q
                A = {A[7:0], Q[7]};
                Q = {Q[6:0], 1'b0};

                // 尝试减法
                if (A[8] == 1'b0 && A[8:1] >= M) begin
                    A[8:1] = A[8:1] - M;
                    Q[0] = 1'b1;
                end

                count = count - 1;
            end

            // 最终结果
            quotient = Q;
            remainder = A[7:0];
        end else begin
            quotient = 8'hFF;
            remainder = dividend;
        end
    end
endmodule
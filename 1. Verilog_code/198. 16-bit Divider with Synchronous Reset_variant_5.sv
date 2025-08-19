//SystemVerilog
module divider_sync_reset_req_ack (
    input clk,
    input reset,
    input [15:0] dividend,
    input [15:0] divisor,
    input req,            // 请求信号
    output reg ack,       // 应答信号
    output reg [15:0] quotient,
    output reg [15:0] remainder
);

    wire valid;
    wire processing;

    // 状态管理子模块
    state_manager u_state_manager (
        .clk(clk),
        .reset(reset),
        .req(req),
        .valid(valid),
        .processing(processing),
        .ack(ack)
    );

    // 计算子模块
    computation u_computation (
        .clk(clk),
        .reset(reset),
        .valid(valid),
        .dividend(dividend),
        .divisor(divisor),
        .quotient(quotient),
        .remainder(remainder),
        .processing(processing)
    );

endmodule

// 状态管理子模块
module state_manager (
    input clk,
    input reset,
    input req,
    output reg valid,
    output reg processing,
    output reg ack
);

    always @(posedge clk or posedge reset) begin
        if (reset) begin
            valid <= 0;
            processing <= 0;
            ack <= 0;
        end else begin
            if (req && !processing) begin
                valid <= 1;
                processing <= 1;
                ack <= 0; // 发送应答前保持ack为0
            end else if (valid) begin
                ack <= 1; // 处理完成，发送应答
                valid <= 0; // 清除有效信号
                processing <= 0; // 重置处理状态
            end else begin
                ack <= 0; // 如果没有有效数据，保持ack为0
            end
        end
    end

endmodule

// 计算子模块
module computation (
    input clk,
    input reset,
    input valid,
    input [15:0] dividend,
    input [15:0] divisor,
    output reg [15:0] quotient,
    output reg [15:0] remainder,
    input processing
);

    always @(posedge clk or posedge reset) begin
        if (reset) begin
            quotient <= 0;
            remainder <= 0;
        end else if (valid) begin
            quotient <= dividend / divisor;
            remainder <= dividend % divisor;
        end
    end

endmodule
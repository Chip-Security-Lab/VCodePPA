//SystemVerilog
// 顶层模块：UART_PreambleDetect
module UART_PreambleDetect #(
    parameter PREAMBLE = 8'hAA,
    parameter PRE_LEN  = 4
)(
    input  wire clk,
    input  wire rxd,
    input  wire rx_done,
    output wire rx_enable,
    output wire preamble_valid
);

    // 内部信号
    wire [7:0] preamble_shift;
    wire [3:0] match_counter;
    wire preamble_match;
    wire preamble_count_enable;

    // Preamble Shift Register 子模块实例化
    UART_PreambleShiftReg u_preamble_shift_reg (
        .clk         (clk),
        .rxd         (rxd),
        .shift_reg_o (preamble_shift)
    );

    // Preamble Match Detector 子模块实例化
    UART_PreambleMatchDetect #(
        .PREAMBLE (PREAMBLE)
    ) u_preamble_match_detect (
        .shift_reg_i    (preamble_shift),
        .preamble_match (preamble_match)
    );

    // Match Counter 子模块实例化
    UART_PreambleMatchCounter #(
        .PRE_LEN (PRE_LEN)
    ) u_preamble_match_counter (
        .clk               (clk),
        .preamble_match    (preamble_match),
        .match_counter_o   (match_counter),
        .preamble_valid_o  (preamble_valid)
    );

    // RX Enable Control 子模块实例化
    UART_RxEnableControl u_rx_enable_control (
        .clk            (clk),
        .preamble_valid (preamble_valid),
        .rx_done        (rx_done),
        .rx_enable      (rx_enable)
    );

endmodule

// -----------------------------------------------------------------------------
// UART_PreambleShiftReg
// 功能：8位移位寄存器，将串行rxd输入移入寄存器
// -----------------------------------------------------------------------------
module UART_PreambleShiftReg (
    input  wire clk,
    input  wire rxd,
    output reg  [7:0] shift_reg_o
);
    always @(posedge clk) begin
        shift_reg_o <= {shift_reg_o[6:0], rxd};
    end
endmodule

// -----------------------------------------------------------------------------
// UART_PreambleMatchDetect
// 功能：检测移位寄存器内容是否与预定义前导码匹配
// -----------------------------------------------------------------------------
module UART_PreambleMatchDetect #(
    parameter PREAMBLE = 8'hAA
)(
    input  wire [7:0] shift_reg_i,
    output wire       preamble_match
);
    assign preamble_match = (shift_reg_i == PREAMBLE);
endmodule

// -----------------------------------------------------------------------------
// UART_PreambleMatchCounter
// 功能：计数连续命中前导码的次数，并输出有效信号
// -----------------------------------------------------------------------------
module UART_PreambleMatchCounter #(
    parameter PRE_LEN = 4
)(
    input  wire       clk,
    input  wire       preamble_match,
    output reg  [3:0] match_counter_o,
    output reg        preamble_valid_o
);
    always @(posedge clk) begin
        if (preamble_match) begin
            if (match_counter_o < PRE_LEN)
                match_counter_o <= match_counter_o + 1'b1;
        end else begin
            match_counter_o <= 4'd0;
        end
        preamble_valid_o <= (match_counter_o == PRE_LEN);
    end
endmodule

// -----------------------------------------------------------------------------
// UART_RxEnableControl
// 功能：根据前导码检测结果和接收完成信号控制rx_enable输出
// -----------------------------------------------------------------------------
module UART_RxEnableControl (
    input  wire clk,
    input  wire preamble_valid,
    input  wire rx_done,
    output reg  rx_enable
);
    always @(posedge clk) begin
        if (preamble_valid)
            rx_enable <= 1'b1;
        else if (rx_done)
            rx_enable <= 1'b0;
    end
endmodule
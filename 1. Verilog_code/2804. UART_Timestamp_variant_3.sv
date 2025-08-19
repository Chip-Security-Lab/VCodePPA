//SystemVerilog
module UART_Timestamp #(
    parameter TS_WIDTH = 32,
    parameter TS_CLK_HZ = 100_000_000
)(
    input wire clk,
    input wire rx_start,
    input wire tx_start,
    output reg [TS_WIDTH-1:0] rx_timestamp,
    output reg [TS_WIDTH-1:0] tx_timestamp,
    input wire ts_sync
);
// 高精度时间计数器
reg [TS_WIDTH-1:0] global_counter;

always @(posedge clk) begin
    if (ts_sync)
        global_counter <= {TS_WIDTH{1'b0}};
    else
        global_counter <= global_counter + 1'b1;
end

// 时间标记捕获（插入流水线寄存器，防止关键路径）
reg rx_start_d1, tx_start_d1;
reg [TS_WIDTH-1:0] global_counter_rxpipe, global_counter_txpipe;

always @(posedge clk) begin
    rx_start_d1 <= rx_start;
    tx_start_d1 <= tx_start;
    global_counter_rxpipe <= global_counter;
    global_counter_txpipe <= global_counter;
end

always @(posedge clk) begin
    if (rx_start_d1)
        rx_timestamp <= global_counter_rxpipe;
    if (tx_start_d1)
        tx_timestamp <= global_counter_txpipe;
end

// 除法参数
parameter TS_CLK_DIVIDEND = 1_000_000;
parameter TS_CLK_DIVISOR = TS_CLK_HZ / TS_CLK_DIVIDEND;

// 移位减法除法器接口信号
reg [TS_WIDTH-1:0] dividend_reg;
reg [TS_WIDTH-1:0] divisor_reg;
reg start_division;
wire [TS_WIDTH-1:0] quotient;
wire [TS_WIDTH-1:0] remainder;
wire division_done;

// 对global_counter的某一时刻进行除法操作（插入流水线寄存器，切割关键路径）
reg rx_start_div_d1;
reg [TS_WIDTH-1:0] global_counter_divpipe;

always @(posedge clk) begin
    rx_start_div_d1 <= rx_start;
    global_counter_divpipe <= global_counter;
end

always @(posedge clk) begin
    if (rx_start_div_d1) begin
        dividend_reg <= global_counter_divpipe;
        divisor_reg  <= TS_CLK_DIVISOR;
        start_division <= 1'b1;
    end else begin
        start_division <= 1'b0;
    end
end

// 移位减法除法器实例化
ShiftSubDivider #(
    .DIV_WIDTH(TS_WIDTH)
) u_shift_sub_divider (
    .clk(clk),
    .rst(ts_sync),
    .start(start_division),
    .dividend(dividend_reg),
    .divisor(divisor_reg),
    .quotient(quotient),
    .remainder(remainder),
    .done(division_done)
);

endmodule

module ShiftSubDivider #(
    parameter DIV_WIDTH = 32
)(
    input wire clk,
    input wire rst,
    input wire start,
    input wire [DIV_WIDTH-1:0] dividend,
    input wire [DIV_WIDTH-1:0] divisor,
    output reg [DIV_WIDTH-1:0] quotient,
    output reg [DIV_WIDTH-1:0] remainder,
    output reg done
);

// 关键路径切割：对移位减法除法器的主要组合操作插入流水线寄存器

reg [DIV_WIDTH-1:0] dividend_reg;
reg [DIV_WIDTH-1:0] divisor_reg;
reg [DIV_WIDTH-1:0] quotient_reg;
reg [DIV_WIDTH-1:0] remainder_reg;
reg [$clog2(DIV_WIDTH+1)-1:0] bit_cnt;
reg busy;

// pipeline registers for critical path cut
reg [DIV_WIDTH-1:0] rem_shifted;
reg [DIV_WIDTH-1:0] div_shifted;
reg [DIV_WIDTH-1:0] quot_shifted;
reg [DIV_WIDTH-1:0] rem_sub;
reg [DIV_WIDTH-1:0] quot_next;
reg [DIV_WIDTH-1:0] rem_next;
reg [DIV_WIDTH-1:0] divisor_pipe;
reg pipeline_valid;
reg [$clog2(DIV_WIDTH+1)-1:0] bit_cnt_pipe;
reg busy_pipe;

always @(posedge clk or posedge rst) begin
    if (rst) begin
        dividend_reg  <= {DIV_WIDTH{1'b0}};
        divisor_reg   <= {DIV_WIDTH{1'b0}};
        quotient_reg  <= {DIV_WIDTH{1'b0}};
        remainder_reg <= {DIV_WIDTH{1'b0}};
        bit_cnt       <= {($clog2(DIV_WIDTH+1)){1'b0}};
        busy          <= 1'b0;
        quotient      <= {DIV_WIDTH{1'b0}};
        remainder     <= {DIV_WIDTH{1'b0}};
        done          <= 1'b0;
        // Pipeline
        rem_shifted   <= {DIV_WIDTH{1'b0}};
        div_shifted   <= {DIV_WIDTH{1'b0}};
        quot_shifted  <= {DIV_WIDTH{1'b0}};
        rem_sub       <= {DIV_WIDTH{1'b0}};
        quot_next     <= {DIV_WIDTH{1'b0}};
        rem_next      <= {DIV_WIDTH{1'b0}};
        divisor_pipe  <= {DIV_WIDTH{1'b0}};
        pipeline_valid<= 1'b0;
        bit_cnt_pipe  <= {($clog2(DIV_WIDTH+1)){1'b0}};
        busy_pipe     <= 1'b0;
    end else begin
        if (start && !busy) begin
            dividend_reg  <= dividend;
            divisor_reg   <= divisor;
            quotient_reg  <= {DIV_WIDTH{1'b0}};
            remainder_reg <= {DIV_WIDTH{1'b0}};
            bit_cnt       <= DIV_WIDTH[$clog2(DIV_WIDTH+1)-1:0];
            busy          <= 1'b1;
            done          <= 1'b0;
            pipeline_valid<= 1'b0;
        end else if (busy) begin
            // Pipeline stage 1: shift
            rem_shifted  <= {remainder_reg[DIV_WIDTH-2:0], dividend_reg[DIV_WIDTH-1]};
            div_shifted  <= {dividend_reg[DIV_WIDTH-2:0], 1'b0};
            quot_shifted <= {quotient_reg[DIV_WIDTH-2:0], 1'b0};
            divisor_pipe <= divisor_reg;
            bit_cnt_pipe <= bit_cnt;
            busy_pipe    <= busy;
            pipeline_valid <= 1'b1;

            // Pipeline stage 2: subtract and set quotient
            if (pipeline_valid) begin
                if (rem_shifted >= divisor_pipe) begin
                    rem_sub   <= rem_shifted - divisor_pipe;
                    quot_next <= {quot_shifted[DIV_WIDTH-2:0], 1'b1};
                end else begin
                    rem_sub   <= rem_shifted;
                    quot_next <= {quot_shifted[DIV_WIDTH-2:0], 1'b0};
                end
                rem_next <= rem_sub;
            end

            // Commit results
            if (pipeline_valid) begin
                dividend_reg  <= div_shifted;
                remainder_reg <= rem_sub;
                quotient_reg  <= quot_next;
                bit_cnt       <= bit_cnt_pipe - 1'b1;
            end

            // Finish division
            if (pipeline_valid && (bit_cnt_pipe == 1)) begin
                quotient  <= quot_next;
                remainder <= rem_sub;
                done      <= 1'b1;
                busy      <= 1'b0;
                pipeline_valid <= 1'b0;
            end else if (pipeline_valid) begin
                done <= 1'b0;
            end
        end else begin
            done <= 1'b0;
            pipeline_valid <= 1'b0;
        end
    end
end

endmodule
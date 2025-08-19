//SystemVerilog
module config_timer #(
    parameter DATA_WIDTH = 24,
    parameter PRESCALE_WIDTH = 8
)(
    input clk_i, rst_i, enable_i,
    input [DATA_WIDTH-1:0] period_i,
    input [PRESCALE_WIDTH-1:0] prescaler_i,
    output reg [DATA_WIDTH-1:0] value_o,
    output expired_o
);
    // 阶段间连接信号
    wire enable_stage2, enable_stage3, enable_stage4, enable_stage5;
    wire prescale_tick_stage2, prescale_tick_stage3, prescale_tick_stage4, prescale_tick_stage5;
    wire [DATA_WIDTH-1:0] value_stage3, value_stage4, value_stage5;
    wire [DATA_WIDTH-1:0] period_stage3, period_stage4;
    wire value_match_stage4;
    wire expired_stage5;
    wire [PRESCALE_WIDTH-1:0] prescale_counter_stage1;

    // 阶段1：预分频计数 - 第一半
    prescaler_stage #(
        .COUNTER_WIDTH(PRESCALE_WIDTH)
    ) prescaler_stage1 (
        .clk_i(clk_i),
        .rst_i(rst_i),
        .enable_i(enable_i),
        .prescaler_i(prescaler_i),
        .counter_o(prescale_counter_stage1),
        .enable_o(enable_stage2)
    );

    // 阶段2：预分频计数 - 第二半
    tick_generator_stage tick_stage2 (
        .clk_i(clk_i),
        .rst_i(rst_i),
        .enable_i(enable_stage2),
        .counter_i(prescale_counter_stage1),
        .prescaler_i(prescaler_i),
        .tick_o(prescale_tick_stage2),
        .enable_o(enable_stage3)
    );

    // 阶段3：计数器逻辑 - 准备
    preparation_stage #(
        .DATA_WIDTH(DATA_WIDTH)
    ) prep_stage3 (
        .clk_i(clk_i),
        .rst_i(rst_i),
        .period_i(period_i),
        .value_feedback_i(value_stage5),
        .tick_i(prescale_tick_stage2),
        .enable_i(enable_stage3),
        .period_o(period_stage3),
        .value_o(value_stage3),
        .tick_o(prescale_tick_stage3),
        .enable_o(enable_stage4)
    );

    // 阶段4：计数器逻辑 - 比较
    comparison_stage #(
        .DATA_WIDTH(DATA_WIDTH)
    ) comp_stage4 (
        .clk_i(clk_i),
        .rst_i(rst_i),
        .value_i(value_stage3),
        .period_i(period_stage3),
        .tick_i(prescale_tick_stage3),
        .enable_i(enable_stage4),
        .value_o(value_stage4),
        .period_o(period_stage4),
        .match_o(value_match_stage4),
        .tick_o(prescale_tick_stage4),
        .enable_o(enable_stage5)
    );

    // 阶段5：计数器逻辑 - 更新
    update_stage #(
        .DATA_WIDTH(DATA_WIDTH)
    ) update_stage5 (
        .clk_i(clk_i),
        .rst_i(rst_i),
        .value_i(value_stage4),
        .match_i(value_match_stage4),
        .tick_i(prescale_tick_stage4),
        .enable_i(enable_stage5),
        .value_o(value_stage5),
        .expired_o(expired_stage5),
        .tick_o(prescale_tick_stage5),
        .output_value_o(value_o)
    );

    // 输出信号生成
    assign expired_o = expired_stage5 && prescale_tick_stage5;
endmodule

// 预分频计数模块
module prescaler_stage #(
    parameter COUNTER_WIDTH = 8
)(
    input clk_i, rst_i, enable_i,
    input [COUNTER_WIDTH-1:0] prescaler_i,
    output reg [COUNTER_WIDTH-1:0] counter_o,
    output reg enable_o
);
    always @(posedge clk_i) begin
        if (rst_i) begin
            counter_o <= 0;
            enable_o <= 0;
        end else if (enable_i) begin
            if (counter_o == prescaler_i) begin
                counter_o <= 0;
            end else begin
                counter_o <= counter_o + 1'b1;
            end
            enable_o <= enable_i;
        end else begin
            enable_o <= 0;
        end
    end
endmodule

// 时钟信号生成模块
module tick_generator_stage (
    input clk_i, rst_i, enable_i,
    input [7:0] counter_i, prescaler_i,
    output reg tick_o, enable_o
);
    always @(posedge clk_i) begin
        if (rst_i) begin
            tick_o <= 0;
            enable_o <= 0;
        end else begin
            tick_o <= enable_i && (counter_i == prescaler_i);
            enable_o <= enable_i;
        end
    end
endmodule

// 准备阶段模块
module preparation_stage #(
    parameter DATA_WIDTH = 24
)(
    input clk_i, rst_i,
    input [DATA_WIDTH-1:0] period_i, value_feedback_i,
    input tick_i, enable_i,
    output reg [DATA_WIDTH-1:0] period_o, value_o,
    output reg tick_o, enable_o
);
    always @(posedge clk_i) begin
        if (rst_i) begin
            period_o <= 0;
            value_o <= 0;
            tick_o <= 0;
            enable_o <= 0;
        end else begin
            period_o <= period_i;
            value_o <= value_feedback_i;
            tick_o <= tick_i;
            enable_o <= enable_i;
        end
    end
endmodule

// 比较阶段模块
module comparison_stage #(
    parameter DATA_WIDTH = 24
)(
    input clk_i, rst_i,
    input [DATA_WIDTH-1:0] value_i, period_i,
    input tick_i, enable_i,
    output reg [DATA_WIDTH-1:0] value_o, period_o,
    output reg match_o, tick_o, enable_o
);
    always @(posedge clk_i) begin
        if (rst_i) begin
            value_o <= 0;
            period_o <= 0;
            match_o <= 0;
            tick_o <= 0;
            enable_o <= 0;
        end else begin
            value_o <= value_i;
            period_o <= period_i;
            match_o <= (value_i == period_i);
            tick_o <= tick_i;
            enable_o <= enable_i;
        end
    end
endmodule

// 更新阶段模块
module update_stage #(
    parameter DATA_WIDTH = 24
)(
    input clk_i, rst_i,
    input [DATA_WIDTH-1:0] value_i,
    input match_i, tick_i, enable_i,
    output reg [DATA_WIDTH-1:0] value_o,
    output reg expired_o, tick_o,
    output reg [DATA_WIDTH-1:0] output_value_o
);
    always @(posedge clk_i) begin
        if (rst_i) begin
            value_o <= 0;
            expired_o <= 0;
            tick_o <= 0;
            output_value_o <= 0;
        end else if (enable_i) begin
            if (tick_i) begin
                if (match_i) begin
                    value_o <= 0;
                end else begin
                    value_o <= value_i + 1'b1;
                end
                expired_o <= match_i;
            end
            tick_o <= tick_i;
            output_value_o <= value_o;
        end
    end
endmodule
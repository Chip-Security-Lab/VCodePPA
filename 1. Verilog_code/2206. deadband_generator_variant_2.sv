//SystemVerilog
module deadband_generator #(
    parameter COUNTER_WIDTH = 10
)(
    input wire clock,
    input wire reset,
    input wire [COUNTER_WIDTH-1:0] period,
    input wire [COUNTER_WIDTH-1:0] deadtime,
    output reg signal_a,
    output reg signal_b
);
    // 内部连线
    wire [COUNTER_WIDTH-1:0] counter;
    wire [COUNTER_WIDTH-1:0] period_reg;
    wire [COUNTER_WIDTH-1:0] deadtime_reg;
    wire [COUNTER_WIDTH-1:0] half_period_minus_deadtime;
    wire [COUNTER_WIDTH-1:0] half_period_plus_deadtime;

    // 寄存输入模块实例化
    input_register #(
        .DATA_WIDTH(COUNTER_WIDTH)
    ) input_reg_inst (
        .clock(clock),
        .reset(reset),
        .period_in(period),
        .deadtime_in(deadtime),
        .period_out(period_reg),
        .deadtime_out(deadtime_reg)
    );
    
    // 计算比较值模块实例化
    comparison_calculator #(
        .DATA_WIDTH(COUNTER_WIDTH)
    ) comp_calc_inst (
        .clock(clock),
        .reset(reset),
        .period_reg(period_reg),
        .deadtime_reg(deadtime_reg),
        .half_period_minus_deadtime(half_period_minus_deadtime),
        .half_period_plus_deadtime(half_period_plus_deadtime)
    );
    
    // 计数器模块实例化
    counter_module #(
        .COUNTER_WIDTH(COUNTER_WIDTH)
    ) counter_inst (
        .clock(clock),
        .reset(reset),
        .period_reg(period_reg),
        .counter(counter)
    );
    
    // 输出信号生成模块实例化
    signal_generator #(
        .COUNTER_WIDTH(COUNTER_WIDTH)
    ) sig_gen_inst (
        .clock(clock),
        .reset(reset),
        .counter(counter),
        .half_period_minus_deadtime(half_period_minus_deadtime),
        .half_period_plus_deadtime(half_period_plus_deadtime),
        .signal_a(signal_a),
        .signal_b(signal_b)
    );
endmodule

//输入寄存模块
module input_register #(
    parameter DATA_WIDTH = 10
)(
    input wire clock,
    input wire reset,
    input wire [DATA_WIDTH-1:0] period_in,
    input wire [DATA_WIDTH-1:0] deadtime_in,
    output reg [DATA_WIDTH-1:0] period_out,
    output reg [DATA_WIDTH-1:0] deadtime_out
);
    always @(posedge clock) begin
        if (reset) begin
            period_out <= {DATA_WIDTH{1'b0}};
            deadtime_out <= {DATA_WIDTH{1'b0}};
        end else begin
            period_out <= period_in;
            deadtime_out <= deadtime_in;
        end
    end
endmodule

//比较值计算模块
module comparison_calculator #(
    parameter DATA_WIDTH = 10
)(
    input wire clock,
    input wire reset,
    input wire [DATA_WIDTH-1:0] period_reg,
    input wire [DATA_WIDTH-1:0] deadtime_reg,
    output reg [DATA_WIDTH-1:0] half_period_minus_deadtime,
    output reg [DATA_WIDTH-1:0] half_period_plus_deadtime
);
    always @(posedge clock) begin
        if (reset) begin
            half_period_minus_deadtime <= {DATA_WIDTH{1'b0}};
            half_period_plus_deadtime <= {DATA_WIDTH{1'b0}};
        end else begin
            half_period_minus_deadtime <= (period_reg >> 1) - deadtime_reg;
            half_period_plus_deadtime <= (period_reg >> 1) + deadtime_reg;
        end
    end
endmodule

//计数器模块
module counter_module #(
    parameter COUNTER_WIDTH = 10
)(
    input wire clock,
    input wire reset,
    input wire [COUNTER_WIDTH-1:0] period_reg,
    output reg [COUNTER_WIDTH-1:0] counter
);
    always @(posedge clock) begin
        if (reset) begin
            counter <= {COUNTER_WIDTH{1'b0}};
        end else begin
            if (counter >= period_reg - 1'b1) begin
                counter <= {COUNTER_WIDTH{1'b0}};
            end else begin
                counter <= counter + 1'b1;
            end
        end
    end
endmodule

//输出信号生成模块
module signal_generator #(
    parameter COUNTER_WIDTH = 10
)(
    input wire clock,
    input wire reset,
    input wire [COUNTER_WIDTH-1:0] counter,
    input wire [COUNTER_WIDTH-1:0] half_period_minus_deadtime,
    input wire [COUNTER_WIDTH-1:0] half_period_plus_deadtime,
    output reg signal_a,
    output reg signal_b
);
    always @(posedge clock) begin
        if (reset) begin
            signal_a <= 1'b0;
            signal_b <= 1'b0;
        end else begin
            // First half of period minus deadtime
            if (counter < half_period_minus_deadtime) begin
                signal_a <= 1'b1;
                signal_b <= 1'b0;
            // Second half of period minus deadtime
            end else if (counter >= half_period_plus_deadtime) begin
                signal_a <= 1'b0;
                signal_b <= 1'b1;
            // Deadband region
            end else begin
                signal_a <= 1'b0;
                signal_b <= 1'b0;
            end
        end
    end
endmodule
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
    reg [COUNTER_WIDTH-1:0] counter;
    reg [1:0] signal_region;
    
    // 预计算常量并使用寄存器存储计算结果
    reg [COUNTER_WIDTH-1:0] half_period;
    reg [COUNTER_WIDTH-1:0] lower_bound;
    reg [COUNTER_WIDTH-1:0] upper_bound;

    // 定义区域状态编码
    localparam REGION_SIGNAL_A = 2'b00;
    localparam REGION_DEADBAND = 2'b01;
    localparam REGION_SIGNAL_B = 2'b10;
    
    // 增加计数器结束指示信号
    wire counter_end = (counter >= period - 1'b1);
    
    always @(posedge clock) begin
        if (reset) begin
            counter <= {COUNTER_WIDTH{1'b0}};
            signal_a <= 1'b0;
            signal_b <= 1'b0;
            signal_region <= REGION_SIGNAL_A;
            half_period <= {COUNTER_WIDTH{1'b0}};
            lower_bound <= {COUNTER_WIDTH{1'b0}};
            upper_bound <= {COUNTER_WIDTH{1'b0}};
        end else begin
            // 计算半周期和边界值 - 将计算从信号区域逻辑中分离出来
            half_period <= period >> 1;
            lower_bound <= (period >> 1) - deadtime;
            upper_bound <= (period >> 1) + deadtime;
            
            // 计数器逻辑 - 使用预计算的结束信号
            if (counter_end) begin
                counter <= {COUNTER_WIDTH{1'b0}};
            end else begin
                counter <= counter + 1'b1;
            end
            
            // 使用预先计算的边界值确定信号区域
            if (counter < lower_bound) begin
                signal_region <= REGION_SIGNAL_A;
            end else if (counter >= upper_bound) begin
                signal_region <= REGION_SIGNAL_B;
            end else begin
                signal_region <= REGION_DEADBAND;
            end
            
            // 直接由信号区域设置输出，减少case语句的逻辑深度
            signal_a <= (signal_region == REGION_SIGNAL_A);
            signal_b <= (signal_region == REGION_SIGNAL_B);
        end
    end
endmodule
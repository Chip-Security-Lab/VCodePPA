//SystemVerilog
// 顶层模块
module watchdog_reset_gen #(
    parameter TIMEOUT = 8
)(
    input  wire clk,
    input  wire watchdog_kick,
    output wire watchdog_reset
);
    // 内部连线
    wire [3:0] counter_value;
    wire       timeout_detected;
    
    // 计数器子模块实例化
    watchdog_counter #(
        .TIMEOUT(TIMEOUT)
    ) counter_inst (
        .clk           (clk),
        .watchdog_kick (watchdog_kick),
        .counter_value (counter_value),
        .timeout_flag  (timeout_detected)
    );
    
    // 复位信号生成子模块实例化
    watchdog_reset_signal reset_signal_inst (
        .clk             (clk),
        .timeout_flag    (timeout_detected),
        .watchdog_reset  (watchdog_reset)
    );
    
endmodule

// 计数器子模块
module watchdog_counter #(
    parameter TIMEOUT = 8
)(
    input  wire       clk,
    input  wire       watchdog_kick,
    output reg  [3:0] counter_value,
    output wire       timeout_flag
);
    // 计数器状态
    reg [1:0] counter_state;
    
    // 定义状态编码
    localparam RESET_COUNTER = 2'b00;
    localparam INCREMENT_COUNTER = 2'b01;
    localparam HOLD_COUNTER = 2'b10;
    
    // 计数器状态选择逻辑
    always @(*) begin
        if (watchdog_kick)
            counter_state = RESET_COUNTER;
        else if (counter_value < TIMEOUT)
            counter_state = INCREMENT_COUNTER;
        else
            counter_state = HOLD_COUNTER;
    end
    
    // 计数器逻辑 - 使用case结构
    always @(posedge clk) begin
        case (counter_state)
            RESET_COUNTER: 
                counter_value <= 4'b0000;
            INCREMENT_COUNTER: 
                counter_value <= counter_value + 1'b1;
            HOLD_COUNTER: 
                counter_value <= counter_value;
            default: 
                counter_value <= counter_value;
        endcase
    end
    
    // 超时检测
    assign timeout_flag = (counter_value >= TIMEOUT);
    
endmodule

// 复位信号生成子模块
module watchdog_reset_signal (
    input  wire clk,
    input  wire timeout_flag,
    output reg  watchdog_reset
);
    // 状态定义
    localparam RESET_INACTIVE = 1'b0;
    localparam RESET_ACTIVE = 1'b1;
    
    // 复位状态
    reg reset_state;
    
    // 复位状态选择逻辑
    always @(*) begin
        reset_state = timeout_flag ? RESET_ACTIVE : RESET_INACTIVE;
    end
    
    // 复位信号生成逻辑 - 使用case结构
    always @(posedge clk) begin
        case (reset_state)
            RESET_INACTIVE:
                watchdog_reset <= 1'b0;
            RESET_ACTIVE:
                watchdog_reset <= 1'b1;
            default:
                watchdog_reset <= 1'b0;
        endcase
    end
    
endmodule
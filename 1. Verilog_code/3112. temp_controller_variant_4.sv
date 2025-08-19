//SystemVerilog
module temp_controller(
    input wire clk,
    input wire reset,
    input wire [7:0] current_temp,
    input wire [7:0] target_temp,
    input wire [1:0] mode, // 00:off, 01:heat, 10:cool, 11:auto
    output reg heater,
    output reg cooler,
    output reg fan,
    output reg [1:0] status // 00:idle, 01:heating, 10:cooling
);
    // 状态定义
    localparam [1:0] OFF = 2'b00, HEATING = 2'b01, 
                    COOLING = 2'b10, IDLE = 2'b11;
    reg [1:0] state, next_state;
    localparam TEMP_THRESHOLD = 8'd2;
    
    // 温度差值计算 - 提前计算以简化逻辑
    wire signed [8:0] temp_diff;
    wire below_threshold, above_threshold, within_threshold;
    
    assign temp_diff = current_temp - target_temp;
    assign below_threshold = $signed(temp_diff) < -$signed({1'b0, TEMP_THRESHOLD});
    assign above_threshold = $signed(temp_diff) > $signed({1'b0, TEMP_THRESHOLD});
    assign within_threshold = !below_threshold && !above_threshold;
    
    // 状态更新和输出逻辑
    always @(posedge clk or posedge reset) begin
        if (reset) begin
            state <= OFF;
            heater <= 1'b0;
            cooler <= 1'b0;
            fan <= 1'b0;
            status <= 2'b00;
        end else begin
            state <= next_state;
            
            // 优化的输出逻辑 - 使用并行赋值
            case (state)
                HEATING: begin
                    heater <= 1'b1;
                    cooler <= 1'b0;
                    fan <= 1'b1;
                    status <= 2'b01;
                end
                COOLING: begin
                    heater <= 1'b0;
                    cooler <= 1'b1;
                    fan <= 1'b1;
                    status <= 2'b10;
                end
                default: begin  // OFF, IDLE
                    heater <= 1'b0;
                    cooler <= 1'b0;
                    fan <= 1'b0;
                    status <= 2'b00;
                end
            endcase
        end
    end
    
    // 优化的状态转换逻辑 - 使用case结构提高可读性和综合效率
    always @(*) begin
        case (mode)
            2'b00: next_state = OFF;
            2'b01: next_state = (temp_diff < 0) ? HEATING : IDLE;
            2'b10: next_state = (temp_diff > 0) ? COOLING : IDLE;
            2'b11: begin // AUTO模式
                if (below_threshold)
                    next_state = HEATING;
                else if (above_threshold)
                    next_state = COOLING;
                else
                    next_state = IDLE;
            end
            default: next_state = state;
        endcase
    end
endmodule
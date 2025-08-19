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
    parameter [1:0] OFF = 2'b00, HEATING = 2'b01, 
                    COOLING = 2'b10, IDLE = 2'b11;
    reg [1:0] state, next_state;
    parameter TEMP_THRESHOLD = 8'd2;
    
    // 状态寄存器
    always @(posedge clk or posedge reset) begin
        if (reset)
            state <= OFF;
        else
            state <= next_state;
    end
    
    // 下一状态逻辑
    always @(*) begin
        case (mode)
            2'b00: next_state = OFF;
            2'b01: next_state = (current_temp < target_temp) ? HEATING : IDLE;
            2'b10: next_state = (current_temp > target_temp) ? COOLING : IDLE;
            2'b11: begin
                if (current_temp < target_temp - TEMP_THRESHOLD)
                    next_state = HEATING;
                else if (current_temp > target_temp + TEMP_THRESHOLD)
                    next_state = COOLING;
                else
                    next_state = IDLE;
            end
        endcase
    end
    
    // 加热器控制
    always @(posedge clk or posedge reset) begin
        if (reset)
            heater <= 1'b0;
        else if (state == HEATING)
            heater <= 1'b1;
        else
            heater <= 1'b0;
    end
    
    // 冷却器控制
    always @(posedge clk or posedge reset) begin
        if (reset)
            cooler <= 1'b0;
        else if (state == COOLING)
            cooler <= 1'b1;
        else
            cooler <= 1'b0;
    end
    
    // 风扇控制
    always @(posedge clk or posedge reset) begin
        if (reset)
            fan <= 1'b0;
        else if (state == HEATING || state == COOLING)
            fan <= 1'b1;
        else
            fan <= 1'b0;
    end
    
    // 状态输出
    always @(posedge clk or posedge reset) begin
        if (reset)
            status <= 2'b00;
        else if (state == HEATING)
            status <= 2'b01;
        else if (state == COOLING)
            status <= 2'b10;
        else
            status <= 2'b00;
    end
endmodule
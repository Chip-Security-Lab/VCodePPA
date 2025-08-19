//SystemVerilog
module pwm_generator(
    input wire clk,
    input wire reset,
    input wire [7:0] duty_cycle,
    input wire [1:0] mode, // 00:off, 01:normal, 10:inverted, 11:center-aligned
    input wire valid,        // 数据有效信号
    output wire ready,       // 准备接收信号
    output reg pwm_out
);
    parameter [1:0] OFF = 2'b00, NORMAL = 2'b01, 
                    INVERTED = 2'b10, CENTER = 2'b11;
    
    reg [1:0] state, next_state;
    reg [7:0] counter;
    reg direction; // 0:up, 1:down
    
    // 内部寄存器，存储有效的配置
    reg [7:0] duty_cycle_reg;
    reg [1:0] mode_reg;
    
    // 握手状态信号
    reg data_received;
    
    // Ready信号生成
    assign ready = ~reset;
    
    always @(posedge clk or posedge reset) begin
        if (reset) begin
            state <= OFF;
            counter <= 8'h00;
            direction <= 0;
            duty_cycle_reg <= 8'h00;
            mode_reg <= 2'b00;
            data_received <= 1'b0;
        end else begin
            // 握手逻辑：当valid和ready同时为高时，接收数据
            if (valid && ready) begin
                duty_cycle_reg <= duty_cycle;
                mode_reg <= mode;
                data_received <= 1'b1;
            end
            
            // 状态更新
            state <= next_state;
            
            // 计数器更新逻辑
            case (state)
                OFF: counter <= 8'h00;
                NORMAL, INVERTED: counter <= counter + 1;
                CENTER: begin
                    if (direction == 0) begin
                        if (counter == 8'hFF)
                            direction <= 1;
                        else
                            counter <= counter + 1;
                    end else begin
                        if (counter == 8'h00)
                            direction <= 0;
                        else
                            counter <= counter - 1;
                    end
                end
            endcase
        end
    end
    
    // 组合逻辑
    always @(*) begin
        // 使用已接收的模式数据决定下一状态
        next_state = (mode_reg == 2'b00) ? OFF : 
                     (mode_reg == 2'b01) ? NORMAL :
                     (mode_reg == 2'b10) ? INVERTED : CENTER;
                     
        case (state)
            OFF: pwm_out = 1'b0;
            NORMAL: pwm_out = (counter < duty_cycle_reg) ? 1'b1 : 1'b0;
            INVERTED: pwm_out = (counter < duty_cycle_reg) ? 1'b0 : 1'b1;
            CENTER: pwm_out = (counter < duty_cycle_reg) ? 1'b1 : 1'b0;
        endcase
    end
endmodule
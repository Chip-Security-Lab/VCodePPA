//SystemVerilog
module oneshot_timer (
    input CLK, RST, TRIGGER,
    input [15:0] PERIOD,
    output reg ACTIVE, DONE
);
    reg [15:0] counter;
    reg trigger_reg;
    reg trigger_d;
    wire trigger_edge;
    
    // 将输入TRIGGER直接寄存起来，避免触发逻辑的组合路径延迟
    always @(posedge CLK) begin
        trigger_reg <= TRIGGER;
        trigger_d <= trigger_reg;
    end
    
    // 计算上升沿检测在寄存器后进行
    assign trigger_edge = trigger_reg & ~trigger_d;
    
    // 状态编码定义
    localparam STATE_IDLE = 2'b00;
    localparam STATE_ACTIVE = 2'b01;
    localparam STATE_DONE = 2'b10;
    
    // 状态信号
    reg [1:0] state;
    
    // 主状态逻辑 - 使用case替代if-else级联
    always @(posedge CLK) begin
        if (RST) begin 
            counter <= 16'd0; 
            ACTIVE <= 1'b0; 
            DONE <= 1'b0;
            state <= STATE_IDLE;
        end
        else begin
            // 默认DONE为0
            DONE <= 1'b0;
            
            case (state)
                STATE_IDLE: begin
                    if (trigger_edge) begin
                        ACTIVE <= 1'b1;
                        counter <= 16'd0;
                        state <= STATE_ACTIVE;
                    end
                end
                
                STATE_ACTIVE: begin
                    counter <= counter + 16'd1;
                    if (counter == PERIOD - 1) begin
                        ACTIVE <= 1'b0;
                        DONE <= 1'b1;
                        state <= STATE_DONE;
                    end
                end
                
                STATE_DONE: begin
                    state <= STATE_IDLE;
                end
                
                default: begin
                    state <= STATE_IDLE;
                end
            endcase
        end
    end
endmodule
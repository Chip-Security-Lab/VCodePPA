//SystemVerilog
module triggered_timer #(parameter CNT_W = 32)(
    input wire clock, n_reset, trigger,
    input wire [CNT_W-1:0] target,
    output reg [CNT_W-1:0] counter,
    output reg complete
);
    localparam IDLE = 1'b0, COUNTING = 1'b1;
    reg state, next_state;
    wire trig_rising;
    
    // 使用边沿检测模块
    edge_detector u_edge_detector (
        .clock(clock),
        .n_reset(n_reset),
        .signal_in(trigger),
        .rising_edge(trig_rising)
    );
    
    // 状态寄存器
    sync_reset_register #(
        .WIDTH(1)
    ) u_state_reg (
        .clock(clock),
        .n_reset(n_reset),
        .d(next_state),
        .q(state)
    );
    
    // 下一状态逻辑
    always @(*) begin
        next_state = state; // 默认：保持当前状态
        case (state)
            IDLE: begin
                if (trig_rising) 
                    next_state = COUNTING;
            end
            COUNTING: begin
                if (counter == target - 1) 
                    next_state = IDLE;
            end
        endcase
    end
    
    // 计数器和完成标志控制
    timer_control #(
        .CNT_W(CNT_W)
    ) u_timer_control (
        .clock(clock),
        .n_reset(n_reset),
        .state(state),
        .trig_rising(trig_rising),
        .target(target),
        .counter(counter),
        .complete(complete)
    );
    
endmodule

// 边沿检测模块
module edge_detector (
    input wire clock, n_reset, signal_in,
    output wire rising_edge
);
    reg signal_d1, signal_d2;
    
    // 双同步器边沿检测
    always @(posedge clock or negedge n_reset) begin
        if (!n_reset) begin 
            signal_d1 <= 1'b0; 
            signal_d2 <= 1'b0; 
        end
        else begin 
            signal_d1 <= signal_in; 
            signal_d2 <= signal_d1; 
        end
    end
    
    assign rising_edge = signal_d1 & ~signal_d2;
    
endmodule

// 同步复位寄存器模块
module sync_reset_register #(
    parameter WIDTH = 1
)(
    input wire clock, n_reset,
    input wire [WIDTH-1:0] d,
    output reg [WIDTH-1:0] q
);
    always @(posedge clock or negedge n_reset) begin
        if (!n_reset) begin
            q <= {WIDTH{1'b0}};
        end 
        else begin
            q <= d;
        end
    end
endmodule

// 计时器控制模块
module timer_control #(
    parameter CNT_W = 32
)(
    input wire clock, n_reset,
    input wire state, trig_rising,
    input wire [CNT_W-1:0] target,
    output reg [CNT_W-1:0] counter,
    output reg complete
);
    localparam IDLE = 1'b0, COUNTING = 1'b1;
    
    // 计数器控制
    always @(posedge clock or negedge n_reset) begin
        if (!n_reset) begin
            counter <= {CNT_W{1'b0}};
        end 
        else if (state == IDLE && trig_rising) begin
            counter <= {CNT_W{1'b0}};
        end
        else if (state == COUNTING) begin
            counter <= counter + 1'b1;
        end
    end
    
    // 完成标志控制
    always @(posedge clock or negedge n_reset) begin
        if (!n_reset) begin
            complete <= 1'b0;
        end
        else if (state == COUNTING && counter == target - 1) begin
            complete <= 1'b1;
        end
        else if (state == IDLE && !trig_rising) begin
            complete <= 1'b0;
        end
    end
endmodule
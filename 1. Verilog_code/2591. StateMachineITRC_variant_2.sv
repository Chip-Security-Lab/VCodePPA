//SystemVerilog
// 顶层模块
module StateMachineITRC (
    input wire clk, rst_n,
    input wire [3:0] irq_in,
    input wire ack, done,
    output reg req,
    output reg [1:0] irq_num
);

    // 状态定义
    parameter [1:0] IDLE = 2'b00;
    parameter [1:0] DETECT = 2'b01;
    parameter [1:0] SERVICE = 2'b10;
    parameter [1:0] WAIT = 2'b11;

    // 内部信号
    wire [1:0] next_state;
    wire [3:0] detected_irqs;
    reg [1:0] current_state;

    // 状态寄存器实例化
    StateRegister state_reg (
        .clk(clk),
        .rst_n(rst_n),
        .next_state(next_state),
        .current_state(current_state)
    );

    // 中断检测器实例化
    IRQDetector irq_detector (
        .clk(clk),
        .rst_n(rst_n),
        .irq_in(irq_in),
        .current_state(current_state),
        .detected_irqs(detected_irqs),
        .irq_num(irq_num)
    );

    // 状态控制器实例化
    StateController state_controller (
        .clk(clk),
        .rst_n(rst_n),
        .current_state(current_state),
        .detected_irqs(detected_irqs),
        .ack(ack),
        .done(done),
        .next_state(next_state),
        .req(req)
    );

endmodule

// 状态寄存器子模块
module StateRegister (
    input wire clk,
    input wire rst_n,
    input wire [1:0] next_state,
    output reg [1:0] current_state
);

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n)
            current_state <= 2'b00;
        else
            current_state <= next_state;
    end

endmodule

// 中断检测器子模块
module IRQDetector (
    input wire clk,
    input wire rst_n,
    input wire [3:0] irq_in,
    input wire [1:0] current_state,
    output reg [3:0] detected_irqs,
    output reg [1:0] irq_num
);

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            detected_irqs <= 4'b0000;
            irq_num <= 2'b00;
        end else if (current_state == 2'b01) begin
            detected_irqs <= irq_in;
            if (irq_in[3]) irq_num <= 2'd3;
            else if (irq_in[2]) irq_num <= 2'd2;
            else if (irq_in[1]) irq_num <= 2'd1;
            else if (irq_in[0]) irq_num <= 2'd0;
        end
    end

endmodule

// 状态控制器子模块
module StateController (
    input wire clk,
    input wire rst_n,
    input wire [1:0] current_state,
    input wire [3:0] detected_irqs,
    input wire ack,
    input wire done,
    output reg [1:0] next_state,
    output reg req
);

    parameter [1:0] IDLE = 2'b00;
    parameter [1:0] DETECT = 2'b01;
    parameter [1:0] SERVICE = 2'b10;
    parameter [1:0] WAIT = 2'b11;

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            next_state <= IDLE;
            req <= 0;
        end else begin
            case (current_state)
                IDLE: begin
                    if (|detected_irqs) next_state = DETECT;
                    else next_state = IDLE;
                end
                DETECT: begin
                    next_state = SERVICE;
                end
                SERVICE: begin
                    req <= 1;
                    if (ack) next_state = WAIT;
                    else next_state = SERVICE;
                end
                WAIT: begin
                    req <= 0;
                    if (done) next_state = IDLE;
                    else next_state = WAIT;
                end
                default: begin
                    next_state = IDLE;
                end
            endcase
        end
    end

endmodule
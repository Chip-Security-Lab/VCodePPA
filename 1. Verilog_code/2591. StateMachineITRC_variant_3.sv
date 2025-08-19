//SystemVerilog
module StateMachineITRC (
    input wire clk, rst_n,
    input wire [3:0] irq_in,
    input wire ack, done,
    output reg req,
    output reg [1:0] irq_num
);

    parameter [1:0] IDLE = 2'b00;
    parameter [1:0] DETECT = 2'b01;
    parameter [1:0] SERVICE = 2'b10;
    parameter [1:0] WAIT = 2'b11;
    
    reg [1:0] current_state, next_state;
    reg [3:0] detected_irqs;
    reg [1:0] irq_priority;
    
    // 优化后的优先级编码器
    always @(*) begin
        casex(irq_in)
            4'b1xxx: irq_priority = 2'd3;
            4'b01xx: irq_priority = 2'd2;
            4'b001x: irq_priority = 2'd1;
            4'b0001: irq_priority = 2'd0;
            default: irq_priority = 2'd0;
        endcase
    end
    
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) current_state <= IDLE;
        else current_state <= next_state;
    end
    
    always @(*) begin
        next_state = current_state;
        if (current_state == IDLE && |irq_in) next_state = DETECT;
        else if (current_state == DETECT) next_state = SERVICE;
        else if (current_state == SERVICE && ack) next_state = WAIT;
        else if (current_state == WAIT && done) next_state = IDLE;
        else if (current_state != IDLE && current_state != DETECT && 
                current_state != SERVICE && current_state != WAIT) next_state = IDLE;
    end
    
    always @(posedge clk) begin
        if (!rst_n) begin
            detected_irqs <= 0;
            req <= 0;
            irq_num <= 0;
        end else begin
            if (current_state == IDLE) detected_irqs <= 0;
            else if (current_state == DETECT) begin
                detected_irqs <= irq_in;
                irq_num <= irq_priority;
            end
            else if (current_state == SERVICE) req <= 1;
            else if (current_state == WAIT) req <= 0;
        end
    end
endmodule
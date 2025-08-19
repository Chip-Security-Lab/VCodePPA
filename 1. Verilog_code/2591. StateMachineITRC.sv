module StateMachineITRC (
    input wire clk, rst_n,
    input wire [3:0] irq_in,
    input wire ack, done,
    output reg req,
    output reg [1:0] irq_num
);
    // Define states as parameters instead of enum
    parameter [1:0] IDLE = 2'b00;
    parameter [1:0] DETECT = 2'b01;
    parameter [1:0] SERVICE = 2'b10;
    parameter [1:0] WAIT = 2'b11;
    
    reg [1:0] current_state, next_state;
    reg [3:0] detected_irqs;
    
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) current_state <= IDLE;
        else current_state <= next_state;
    end
    
    always @(*) begin
        next_state = current_state;
        case (current_state)
            IDLE: if (|irq_in) next_state = DETECT;
            DETECT: next_state = SERVICE;
            SERVICE: if (ack) next_state = WAIT;
            WAIT: if (done) next_state = IDLE;
            default: next_state = IDLE;
        endcase
    end
    
    always @(posedge clk) begin
        if (!rst_n) begin
            detected_irqs <= 0; req <= 0; irq_num <= 0;
        end else begin
            case (current_state)
                IDLE: detected_irqs <= 0;
                DETECT: begin
                    detected_irqs <= irq_in;
                    // Priority encoder instead of loop
                    if (irq_in[3]) irq_num <= 2'd3;
                    else if (irq_in[2]) irq_num <= 2'd2;
                    else if (irq_in[1]) irq_num <= 2'd1;
                    else if (irq_in[0]) irq_num <= 2'd0;
                end
                SERVICE: req <= 1;
                WAIT: req <= 0;
                default: begin end
            endcase
        end
    end
endmodule
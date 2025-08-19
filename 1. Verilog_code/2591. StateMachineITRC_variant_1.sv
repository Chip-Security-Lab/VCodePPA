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
    
    // Priority encoder for irq_num
    wire [1:0] priority_irq_num;
    assign priority_irq_num = irq_in[3] ? 2'd3 :
                              irq_in[2] ? 2'd2 :
                              irq_in[1] ? 2'd1 :
                              irq_in[0] ? 2'd0 : 2'd0;
    
    // State transition logic
    always @(*) begin
        case (current_state)
            IDLE: next_state = (|irq_in) ? DETECT : IDLE;
            DETECT: next_state = SERVICE;
            SERVICE: next_state = ack ? WAIT : SERVICE;
            WAIT: next_state = done ? IDLE : WAIT;
            default: next_state = IDLE;
        endcase
    end
    
    // Sequential logic
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            current_state <= IDLE;
            detected_irqs <= 4'b0;
            req <= 1'b0;
            irq_num <= 2'b0;
        end
        else begin
            current_state <= next_state;
            
            case (current_state)
                IDLE: begin
                    detected_irqs <= 4'b0;
                end
                DETECT: begin
                    detected_irqs <= irq_in;
                    irq_num <= priority_irq_num;
                end
                SERVICE: begin
                    req <= 1'b1;
                end
                WAIT: begin
                    req <= 1'b0;
                end
            endcase
        end
    end
endmodule
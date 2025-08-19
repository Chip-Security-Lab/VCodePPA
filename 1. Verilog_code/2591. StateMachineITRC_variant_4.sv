//SystemVerilog
module StateMachineITRC (
    input wire clk, rst_n,
    input wire [3:0] irq_in,
    input wire ack, done,
    output reg req,
    output reg [1:0] irq_num
);

    // State definitions
    parameter [1:0] IDLE = 2'b00;
    parameter [1:0] DETECT = 2'b01;
    parameter [1:0] SERVICE = 2'b10;
    parameter [1:0] WAIT = 2'b11;
    
    // State registers
    reg [1:0] current_state, next_state;
    
    // IRQ processing pipeline registers
    reg [3:0] irq_in_reg;
    reg [3:0] detected_irqs;
    reg [1:0] priority_encoded_irq;
    reg irq_valid;
    
    // Pipeline stage 1: Input registration
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            irq_in_reg <= 4'b0;
        end else begin
            irq_in_reg <= irq_in;
        end
    end
    
    // Pipeline stage 2: Priority encoding
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            priority_encoded_irq <= 2'b0;
            irq_valid <= 1'b0;
        end else begin
            irq_valid <= |irq_in_reg;
            priority_encoded_irq <= irq_in_reg[3] ? 2'd3 :
                                  irq_in_reg[2] ? 2'd2 :
                                  irq_in_reg[1] ? 2'd1 :
                                  irq_in_reg[0] ? 2'd0 : 2'd0;
        end
    end
    
    // State transition logic
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            current_state <= IDLE;
        end else begin
            current_state <= next_state;
        end
    end
    
    // Next state logic
    always @(*) begin
        case (current_state)
            IDLE: next_state = irq_valid ? DETECT : IDLE;
            DETECT: next_state = SERVICE;
            SERVICE: next_state = ack ? WAIT : SERVICE;
            WAIT: next_state = done ? IDLE : WAIT;
            default: next_state = IDLE;
        endcase
    end
    
    // Output and control logic
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            detected_irqs <= 4'b0;
            req <= 1'b0;
            irq_num <= 2'b0;
        end else begin
            case (current_state)
                IDLE: begin
                    detected_irqs <= 4'b0;
                    req <= 1'b0;
                end
                DETECT: begin
                    detected_irqs <= irq_in_reg;
                    irq_num <= priority_encoded_irq;
                end
                SERVICE: req <= 1'b1;
                WAIT: req <= 1'b0;
                default: begin end
            endcase
        end
    end
endmodule
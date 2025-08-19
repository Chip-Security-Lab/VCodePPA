//SystemVerilog
module pulse_recovery_unit (
    input wire clk,
    input wire rst_n,
    input wire noisy_pulse,
    output reg clean_pulse,
    output reg pulse_detected
);
    localparam IDLE = 2'b00;
    localparam PULSE_START = 2'b01;
    localparam PULSE_ACTIVE = 2'b10;
    localparam RECOVERY = 2'b11;
    
    reg [1:0] state, next_state;
    reg [3:0] count, next_count;
    reg next_clean_pulse;
    reg next_pulse_detected;
    
    // State register
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) 
            state <= IDLE;
        else 
            state <= next_state;
    end
    
    // Next state logic
    always @(*) begin
        case (state)
            IDLE:       next_state = noisy_pulse ? PULSE_START : IDLE;
            PULSE_START: next_state = PULSE_ACTIVE;
            PULSE_ACTIVE: next_state = count >= 4'd8 ? RECOVERY : PULSE_ACTIVE;
            RECOVERY:   next_state = count >= 4'd4 ? IDLE : RECOVERY;
            default:    next_state = IDLE;
        endcase
    end
    
    // Counter logic
    always @(*) begin
        next_count = count;
        case (state)
            IDLE:       next_count = 4'd0;
            PULSE_START: next_count = 4'd0;
            PULSE_ACTIVE: next_count = count + 1'b1;
            RECOVERY:   next_count = count + 1'b1;
            default:    next_count = 4'd0;
        endcase
    end
    
    // Counter register
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n)
            count <= 4'd0;
        else
            count <= next_count;
    end
    
    // Clean pulse output logic
    always @(*) begin
        case (state)
            IDLE:       next_clean_pulse = 1'b0;
            PULSE_START: next_clean_pulse = 1'b1;
            PULSE_ACTIVE: next_clean_pulse = 1'b1;
            RECOVERY:   next_clean_pulse = 1'b0;
            default:    next_clean_pulse = 1'b0;
        endcase
    end
    
    // Clean pulse register
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n)
            clean_pulse <= 1'b0;
        else
            clean_pulse <= next_clean_pulse;
    end
    
    // Pulse detected output logic
    always @(*) begin
        case (state)
            IDLE:       next_pulse_detected = 1'b0;
            PULSE_START: next_pulse_detected = 1'b1;
            PULSE_ACTIVE: next_pulse_detected = 1'b1;
            RECOVERY:   next_pulse_detected = 1'b0;
            default:    next_pulse_detected = 1'b0;
        endcase
    end
    
    // Pulse detected register
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n)
            pulse_detected <= 1'b0;
        else
            pulse_detected <= next_pulse_detected;
    end
    
endmodule
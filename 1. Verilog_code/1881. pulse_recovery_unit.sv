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
    reg [3:0] count;
    
    // State machine
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) state <= IDLE;
        else state <= next_state;
    end
    
    // Next state logic
    always @(*) begin
        case (state)
            IDLE: next_state = noisy_pulse ? PULSE_START : IDLE;
            PULSE_START: next_state = PULSE_ACTIVE;
            PULSE_ACTIVE: next_state = count >= 4'd8 ? RECOVERY : PULSE_ACTIVE;
            RECOVERY: next_state = count >= 4'd4 ? IDLE : RECOVERY;
            default: next_state = IDLE;
        endcase
    end
    
    // Output and counter logic
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            count <= 4'd0;
            clean_pulse <= 1'b0;
            pulse_detected <= 1'b0;
        end else begin
            case (state)
                IDLE: begin
                    count <= 4'd0;
                    clean_pulse <= 1'b0;
                    pulse_detected <= 1'b0;
                end
                PULSE_START: begin
                    count <= 4'd0;
                    clean_pulse <= 1'b1;
                    pulse_detected <= 1'b1;
                end
                PULSE_ACTIVE: begin
                    count <= count + 1'b1;
                    clean_pulse <= 1'b1;
                end
                RECOVERY: begin
                    count <= count + 1'b1;
                    clean_pulse <= 1'b0;
                    pulse_detected <= 1'b0;
                end
            endcase
        end
    end
endmodule
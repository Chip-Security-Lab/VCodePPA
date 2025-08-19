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
    reg [3:0] count;
    
    // Buffer registers for high fanout signals
    reg [1:0] state_buf;
    reg [1:0] next_state_buf;
    reg [3:0] count_buf;
    reg [3:0] count_buf2;
    reg [1:0] state_buf2;
    
    // State machine with buffering
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            state <= IDLE;
            state_buf <= IDLE;
            state_buf2 <= IDLE;
        end else begin
            state <= next_state_buf;
            state_buf <= next_state;
            state_buf2 <= state_buf;
        end
    end
    
    // Next state logic with buffering
    always @(*) begin
        case (state_buf2)
            IDLE: next_state = noisy_pulse ? PULSE_START : IDLE;
            PULSE_START: next_state = PULSE_ACTIVE;
            PULSE_ACTIVE: next_state = count_buf2 >= 4'd8 ? RECOVERY : PULSE_ACTIVE;
            RECOVERY: next_state = count_buf2 >= 4'd4 ? IDLE : RECOVERY;
            default: next_state = IDLE;
        endcase
    end
    
    // Counter buffering
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            count <= 4'd0;
            count_buf <= 4'd0;
            count_buf2 <= 4'd0;
        end else begin
            count_buf <= count;
            count_buf2 <= count_buf;
        end
    end
    
    // Output and counter logic with buffering
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            count <= 4'd0;
            clean_pulse <= 1'b0;
            pulse_detected <= 1'b0;
            next_state_buf <= IDLE;
        end else begin
            next_state_buf <= next_state;
            case (state_buf)
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
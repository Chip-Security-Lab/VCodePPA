module fsm_signal_recovery (
    input wire clk, rst_n,
    input wire signal_detect,
    input wire [3:0] signal_value,
    output reg [3:0] recovered_value,
    output reg lock_status
);
    localparam IDLE = 2'b00, DETECT = 2'b01, LOCK = 2'b10, TRACK = 2'b11;
    reg [1:0] state, next_state;
    reg [3:0] counter;
    
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) state <= IDLE;
        else state <= next_state;
    end
    
    always @(*) begin
        case (state)
            IDLE: next_state = signal_detect ? DETECT : IDLE;
            DETECT: next_state = (counter >= 4'd8) ? LOCK : DETECT;
            LOCK: next_state = signal_detect ? TRACK : IDLE;
            TRACK: next_state = signal_detect ? TRACK : IDLE;
            default: next_state = IDLE;
        endcase
    end
    
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            counter <= 4'd0;
            recovered_value <= 4'd0;
            lock_status <= 1'b0;
        end else case (state)
            IDLE: begin
                counter <= 4'd0;
                lock_status <= 1'b0;
            end
            DETECT: counter <= counter + 1'b1;
            LOCK: begin
                recovered_value <= signal_value;
                lock_status <= 1'b1;
            end
            TRACK: recovered_value <= signal_value;
        endcase
    end
endmodule
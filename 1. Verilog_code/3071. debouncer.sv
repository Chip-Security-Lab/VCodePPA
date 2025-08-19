module debouncer(
    input wire clk, rst_n,
    input wire button_in,
    input wire [15:0] debounce_time,
    output reg button_out
);
    localparam IDLE=2'b00, PRESS_DETECT=2'b01, 
               RELEASE_DETECT=2'b10, DEBOUNCE=2'b11;
    reg [1:0] state, next;
    reg [15:0] counter;
    reg btn_sync1, btn_sync2;
    
    // Double flop synchronizer
    always @(posedge clk)
        if (!rst_n) begin
            btn_sync1 <= 1'b0;
            btn_sync2 <= 1'b0;
        end else begin
            btn_sync1 <= button_in;
            btn_sync2 <= btn_sync1;
        end
    
    always @(posedge clk or negedge rst_n)
        if (!rst_n) begin
            state <= IDLE;
            counter <= 16'd0;
            button_out <= 1'b0;
        end else begin
            state <= next;
            
            case (state)
                IDLE: counter <= 16'd0;
                PRESS_DETECT: begin
                    counter <= counter + 16'd1;
                    if (counter >= debounce_time && btn_sync2)
                        button_out <= 1'b1;
                end
                RELEASE_DETECT: begin
                    counter <= counter + 16'd1;
                    if (counter >= debounce_time && !btn_sync2)
                        button_out <= 1'b0;
                end
                DEBOUNCE: counter <= 16'd0;
            endcase
        end
    
    always @(*)
        case (state)
            IDLE: next = btn_sync2 ? PRESS_DETECT : IDLE;
            PRESS_DETECT: next = (counter >= debounce_time) ? 
                            (btn_sync2 ? DEBOUNCE : IDLE) : PRESS_DETECT;
            RELEASE_DETECT: next = (counter >= debounce_time) ? 
                             (!btn_sync2 ? IDLE : DEBOUNCE) : RELEASE_DETECT;
            DEBOUNCE: next = btn_sync2 ? DEBOUNCE : RELEASE_DETECT;
            default: next = IDLE;
        endcase
endmodule
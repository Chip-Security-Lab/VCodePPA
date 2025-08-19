//SystemVerilog
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
    wire counter_done;
    
    // Double flop synchronizer with reset optimization
    always @(posedge clk or negedge rst_n)
        if (!rst_n) {btn_sync1, btn_sync2} <= 2'b00;
        else {btn_sync1, btn_sync2} <= {button_in, btn_sync1};
    
    // Optimized counter done signal
    assign counter_done = (counter >= debounce_time);
    
    // Optimized state machine with reduced logic levels
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
                    if (counter_done & btn_sync2) button_out <= 1'b1;
                end
                RELEASE_DETECT: begin
                    counter <= counter + 16'd1;
                    if (counter_done & ~btn_sync2) button_out <= 1'b0;
                end
                DEBOUNCE: counter <= 16'd0;
            endcase
        end
    
    // Optimized next state logic with priority encoding
    always @(*) begin
        case (state)
            IDLE: next = btn_sync2 ? PRESS_DETECT : IDLE;
            PRESS_DETECT: next = counter_done ? (btn_sync2 ? DEBOUNCE : IDLE) : PRESS_DETECT;
            RELEASE_DETECT: next = counter_done ? (~btn_sync2 ? IDLE : DEBOUNCE) : RELEASE_DETECT;
            DEBOUNCE: next = btn_sync2 ? DEBOUNCE : RELEASE_DETECT;
            default: next = IDLE;
        endcase
    end
endmodule
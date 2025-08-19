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
    wire counter_match;
    
    // Double flop synchronizer with reset optimization
    always @(posedge clk or negedge rst_n)
        if (!rst_n) {btn_sync1, btn_sync2} <= 2'b00;
        else {btn_sync1, btn_sync2} <= {button_in, btn_sync1};
    
    // Counter match detection with pipeline register
    reg counter_match_reg;
    always @(posedge clk or negedge rst_n)
        if (!rst_n) counter_match_reg <= 1'b0;
        else counter_match_reg <= (counter >= debounce_time);
    assign counter_match = counter_match_reg;
    
    // State machine with optimized transitions and buffered next state
    reg [1:0] next_buf;
    always @(posedge clk or negedge rst_n)
        if (!rst_n) begin
            state <= IDLE;
            counter <= 16'd0;
            button_out <= 1'b0;
            next_buf <= IDLE;
        end else begin
            state <= next_buf;
            next_buf <= next;
            
            case (state)
                IDLE: begin
                    counter <= 16'd0;
                    button_out <= button_out;
                end
                PRESS_DETECT: begin
                    counter <= counter + 16'd1;
                    button_out <= counter_match & btn_sync2;
                end
                RELEASE_DETECT: begin
                    counter <= counter + 16'd1;
                    button_out <= ~(counter_match & ~btn_sync2);
                end
                DEBOUNCE: begin
                    counter <= 16'd0;
                    button_out <= button_out;
                end
            endcase
        end
    
    // Optimized next state logic with buffered signals
    reg btn_sync2_buf;
    always @(posedge clk or negedge rst_n)
        if (!rst_n) btn_sync2_buf <= 1'b0;
        else btn_sync2_buf <= btn_sync2;
    
    always @(*)
        case (state)
            IDLE: next = btn_sync2_buf ? PRESS_DETECT : IDLE;
            PRESS_DETECT: next = counter_match ? (btn_sync2_buf ? DEBOUNCE : IDLE) : PRESS_DETECT;
            RELEASE_DETECT: next = counter_match ? (btn_sync2_buf ? DEBOUNCE : IDLE) : RELEASE_DETECT;
            DEBOUNCE: next = btn_sync2_buf ? DEBOUNCE : RELEASE_DETECT;
            default: next = IDLE;
        endcase
endmodule
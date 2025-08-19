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
    reg [15:0] counter_next;
    reg button_out_next;
    reg [1:0] state_next;
    
    // Double flop synchronizer
    always @(posedge clk) begin
        if (!rst_n) begin
            btn_sync1 <= 1'b0;
            btn_sync2 <= 1'b0;
        end else begin
            btn_sync1 <= button_in;
            btn_sync2 <= btn_sync1;
        end
    end
    
    // Next state and counter logic
    always @(*) begin
        counter_next = counter;
        button_out_next = button_out;
        state_next = state;
        
        case (state)
            IDLE: begin
                counter_next = 16'd0;
                if (btn_sync2) begin
                    state_next = PRESS_DETECT;
                end else begin
                    state_next = IDLE;
                end
            end
            PRESS_DETECT: begin
                counter_next = counter + 16'd1;
                if (counter >= debounce_time) begin
                    if (btn_sync2) begin
                        button_out_next = 1'b1;
                        state_next = DEBOUNCE;
                    end else begin
                        state_next = IDLE;
                    end
                end
            end
            RELEASE_DETECT: begin
                counter_next = counter + 16'd1;
                if (counter >= debounce_time) begin
                    if (!btn_sync2) begin
                        button_out_next = 1'b0;
                        state_next = IDLE;
                    end else begin
                        state_next = DEBOUNCE;
                    end
                end
            end
            DEBOUNCE: begin
                counter_next = 16'd0;
                if (btn_sync2) begin
                    state_next = DEBOUNCE;
                end else begin
                    state_next = RELEASE_DETECT;
                end
            end
            default: state_next = IDLE;
        endcase
    end
    
    // Sequential logic
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            state <= IDLE;
            counter <= 16'd0;
            button_out <= 1'b0;
        end else begin
            state <= state_next;
            counter <= counter_next;
            button_out <= button_out_next;
        end
    end
endmodule
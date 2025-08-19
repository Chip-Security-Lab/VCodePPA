//SystemVerilog
module key_debouncer(
    input wire clk,
    input wire reset,
    input wire key_in,
    output reg key_pressed,
    output reg key_released
);
    wire [1:0] state;
    wire [1:0] next_state;
    wire [15:0] debounce_counter;
    
    // State machine for key detection
    key_state_machine fsm (
        .clk(clk),
        .reset(reset),
        .key_in(key_in),
        .next_state(next_state),
        .state(state)
    );

    // Debounce counter
    debounce_counter_module debounce (
        .clk(clk),
        .reset(reset),
        .state(state),
        .debounce_counter(debounce_counter),
        .key_pressed(key_pressed),
        .key_released(key_released)
    );

endmodule

module key_state_machine(
    input wire clk,
    input wire reset,
    input wire key_in,
    output reg [1:0] next_state,
    output reg [1:0] state
);
    parameter [1:0] IDLE = 2'b00, DETECTED = 2'b01, 
                    PRESSED = 2'b10, RELEASED = 2'b11;

    always @(posedge clk or posedge reset) begin
        if (reset) begin
            state <= IDLE;
        end else begin
            state <= next_state;
        end
    end

    always @(*) begin
        case (state)
            IDLE: begin
                if (key_in)
                    next_state = DETECTED;
                else
                    next_state = IDLE;
            end
            DETECTED: begin
                if (!key_in)
                    next_state = IDLE;
                else
                    next_state = PRESSED;
            end
            PRESSED: begin
                if (!key_in)
                    next_state = RELEASED;
                else
                    next_state = PRESSED;
            end
            RELEASED: begin
                next_state = IDLE;
            end
            default: next_state = IDLE;
        endcase
    end
endmodule

module debounce_counter_module(
    input wire clk,
    input wire reset,
    input wire [1:0] state,
    output reg [15:0] debounce_counter,
    output reg key_pressed,
    output reg key_released
);
    reg [15:0] DEBOUNCE_TIME = 16'd1000;

    always @(posedge clk or posedge reset) begin
        if (reset) begin
            debounce_counter <= 16'd0;
            key_pressed <= 1'b0;
            key_released <= 1'b0;
        end else begin
            case (state)
                2'b00: begin // IDLE
                    key_pressed <= 1'b0;
                    key_released <= 1'b0;
                    debounce_counter <= 16'd0;
                end
                2'b01: begin // DETECTED
                    debounce_counter <= debounce_counter + 1'b1;
                end
                2'b10: begin // PRESSED
                    key_pressed <= 1'b1;
                    key_released <= 1'b0;
                end
                2'b11: begin // RELEASED
                    key_pressed <= 1'b0;
                    key_released <= 1'b1;
                end
            endcase
        end
    end
endmodule
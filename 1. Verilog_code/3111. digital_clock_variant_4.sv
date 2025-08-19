//SystemVerilog
module digital_clock(
    input wire clk,
    input wire rst,
    input wire [1:0] mode, // 00:normal, 01:set_hour, 10:set_minute
    input wire inc_value,
    output wire [5:0] hours,
    output wire [5:0] minutes,
    output wire [5:0] seconds
);

    wire [5:0] hours_out, minutes_out, seconds_out;
    wire [3:0] state, next_state;

    // Instantiate the state machine
    state_machine sm (
        .clk(clk),
        .rst(rst),
        .mode(mode),
        .next_state(next_state),
        .state(state)
    );

    // Instantiate the time keeper
    time_keeper tk (
        .clk(clk),
        .rst(rst),
        .state(state),
        .inc_value(inc_value),
        .hours(hours_out),
        .minutes(minutes_out),
        .seconds(seconds_out)
    );

    assign hours = hours_out;
    assign minutes = minutes_out;
    assign seconds = seconds_out;

endmodule

module state_machine(
    input wire clk,
    input wire rst,
    input wire [1:0] mode,
    output reg [3:0] next_state,
    output reg [3:0] state
);
    parameter [3:0] NORMAL = 4'b0001, SET_HOUR = 4'b0010, 
                    SET_MIN = 4'b0100;

    always @(posedge clk or posedge rst) begin
        if (rst) begin
            state <= NORMAL;
        end else begin
            state <= next_state;
        end
    end

    always @(*) begin
        case (mode)
            2'b00: next_state = NORMAL;
            2'b01: next_state = SET_HOUR;
            2'b10: next_state = SET_MIN;
            default: next_state = NORMAL;
        endcase
    end
endmodule

module time_keeper(
    input wire clk,
    input wire rst,
    input wire [3:0] state,
    input wire inc_value,
    output reg [5:0] hours,
    output reg [5:0] minutes,
    output reg [5:0] seconds
);
    reg [16:0] prescaler;

    always @(posedge clk or posedge rst) begin
        if (rst) begin
            hours <= 6'd0;
            minutes <= 6'd0;
            seconds <= 6'd0;
            prescaler <= 17'd0;
        end else begin
            case (state)
                4'b0001: begin // NORMAL
                    prescaler <= prescaler + 1'b1;
                    if (prescaler >= 17'd99999) begin // Assuming 1MHz clock for simulation
                        prescaler <= 17'd0;
                        seconds <= seconds + 1'b1;
                        if (seconds >= 6'd59) begin
                            seconds <= 6'd0;
                            minutes <= minutes + 1'b1;
                            if (minutes >= 6'd59) begin
                                minutes <= 6'd0;
                                hours <= hours + 1'b1;
                                if (hours >= 6'd23)
                                    hours <= 6'd0;
                            end
                        end
                    end
                end
                4'b0010: begin // SET_HOUR
                    if (inc_value) begin
                        hours <= (hours >= 6'd23) ? 6'd0 : hours + 1'b1;
                    end
                end
                4'b0100: begin // SET_MIN
                    if (inc_value) begin
                        minutes <= (minutes >= 6'd59) ? 6'd0 : minutes + 1'b1;
                    end
                end
            endcase
        end
    end
endmodule
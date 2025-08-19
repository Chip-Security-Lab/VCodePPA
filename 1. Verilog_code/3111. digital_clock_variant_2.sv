//SystemVerilog
module digital_clock_pipeline(
    input wire clk,
    input wire rst,
    input wire [1:0] mode,
    input wire inc_value,
    output reg [5:0] hours_stage4,
    output reg [5:0] minutes_stage4,
    output reg [5:0] seconds_stage4
);

    parameter [1:0] NORMAL = 2'b00, SET_HOUR = 2'b01, 
                   SET_MIN = 2'b10, UPDATE = 2'b11;
    
    wire [1:0] state_stage1;
    wire [16:0] prescaler_stage1;
    wire [5:0] hours_stage2, minutes_stage2, seconds_stage2;
    wire [5:0] hours_stage3, minutes_stage3, seconds_stage3;
    
    state_controller state_ctrl(
        .clk(clk),
        .rst(rst),
        .mode(mode),
        .state_out(state_stage1)
    );
    
    prescaler prescaler_unit(
        .clk(clk),
        .rst(rst),
        .state(state_stage1),
        .prescaler_out(prescaler_stage1)
    );
    
    time_counter_stage2 time_counter_stage2_unit(
        .clk(clk),
        .rst(rst),
        .state(state_stage1),
        .prescaler(prescaler_stage1),
        .inc_value(inc_value),
        .hours_out(hours_stage2),
        .minutes_out(minutes_stage2),
        .seconds_out(seconds_stage2)
    );

    time_counter_stage3 time_counter_stage3_unit(
        .clk(clk),
        .rst(rst),
        .hours_in(hours_stage2),
        .minutes_in(minutes_stage2),
        .seconds_in(seconds_stage2),
        .hours_out(hours_stage3),
        .minutes_out(minutes_stage3),
        .seconds_out(seconds_stage3)
    );

    time_counter_stage4 time_counter_stage4_unit(
        .clk(clk),
        .rst(rst),
        .hours_in(hours_stage3),
        .minutes_in(minutes_stage3),
        .seconds_in(seconds_stage3),
        .hours_out(hours_stage4),
        .minutes_out(minutes_stage4),
        .seconds_out(seconds_stage4)
    );

endmodule

module state_controller(
    input wire clk,
    input wire rst,
    input wire [1:0] mode,
    output reg [1:0] state_out
);
    parameter [1:0] NORMAL = 2'b00, SET_HOUR = 2'b01, 
                   SET_MIN = 2'b10, UPDATE = 2'b11;
    
    always @(posedge clk or posedge rst) begin
        if (rst)
            state_out <= NORMAL;
        else begin
            case (mode)
                2'b00: state_out <= NORMAL;
                2'b01: state_out <= SET_HOUR;
                2'b10: state_out <= SET_MIN;
                default: state_out <= NORMAL;
            endcase
        end
    end
endmodule

module prescaler(
    input wire clk,
    input wire rst,
    input wire [1:0] state,
    output reg [16:0] prescaler_out
);
    always @(posedge clk or posedge rst) begin
        if (rst)
            prescaler_out <= 17'd0;
        else if (state == 2'b00)
            prescaler_out <= prescaler_out + 1'b1;
        else
            prescaler_out <= 17'd0;
    end
endmodule

module time_counter_stage2(
    input wire clk,
    input wire rst,
    input wire [1:0] state,
    input wire [16:0] prescaler,
    input wire inc_value,
    output reg [5:0] hours_out,
    output reg [5:0] minutes_out,
    output reg [5:0] seconds_out
);
    reg [5:0] next_seconds;
    
    always @(posedge clk) begin
        if (rst) begin
            hours_out <= 6'd0;
            minutes_out <= 6'd0;
            seconds_out <= 6'd0;
            next_seconds <= 6'd0;
        end else begin
            case (state)
                2'b00: begin
                    if (prescaler >= 17'd99999) begin
                        next_seconds <= seconds_out + 1'b1;
                        seconds_out <= next_seconds;
                    end
                end
                2'b01: begin
                    if (inc_value)
                        hours_out <= (hours_out >= 6'd23) ? 6'd0 : hours_out + 1'b1;
                end
                2'b10: begin
                    if (inc_value)
                        minutes_out <= (minutes_out >= 6'd59) ? 6'd0 : minutes_out + 1'b1;
                end
            endcase
        end
    end
endmodule

module time_counter_stage3(
    input wire clk,
    input wire rst,
    input wire [5:0] hours_in,
    input wire [5:0] minutes_in,
    input wire [5:0] seconds_in,
    output reg [5:0] hours_out,
    output reg [5:0] minutes_out,
    output reg [5:0] seconds_out
);
    always @(posedge clk) begin
        if (rst) begin
            hours_out <= 6'd0;
            minutes_out <= 6'd0;
            seconds_out <= 6'd0;
        end else begin
            seconds_out <= seconds_in;
            if (seconds_in >= 6'd59) begin
                minutes_out <= minutes_in + 1'b1;
            end else begin
                minutes_out <= minutes_in;
            end
            hours_out <= hours_in;
        end
    end
endmodule

module time_counter_stage4(
    input wire clk,
    input wire rst,
    input wire [5:0] hours_in,
    input wire [5:0] minutes_in,
    input wire [5:0] seconds_in,
    output reg [5:0] hours_out,
    output reg [5:0] minutes_out,
    output reg [5:0] seconds_out
);
    always @(posedge clk) begin
        if (rst) begin
            hours_out <= 6'd0;
            minutes_out <= 6'd0;
            seconds_out <= 6'd0;
        end else begin
            seconds_out <= seconds_in;
            minutes_out <= minutes_in;
            if (minutes_in >= 6'd59) begin
                hours_out <= (hours_in >= 6'd23) ? 6'd0 : hours_in + 1'b1;
            end else begin
                hours_out <= hours_in;
            end
        end
    end
endmodule
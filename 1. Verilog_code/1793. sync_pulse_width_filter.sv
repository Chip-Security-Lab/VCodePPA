module sync_pulse_width_filter #(
    parameter MIN_WIDTH = 3,
    parameter MAX_WIDTH = 10,
    parameter CNT_WIDTH = 4
)(
    input clk, rst_n,
    input pulse_in,
    output reg pulse_out
);
    reg [CNT_WIDTH-1:0] count;
    reg prev_pulse;
    
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            count <= 0;
            pulse_out <= 0;
            prev_pulse <= 0;
        end else begin
            prev_pulse <= pulse_in;
            
            if (pulse_in && !prev_pulse) begin
                // Rising edge - start counting
                count <= 1;
                pulse_out <= 0;
            end else if (pulse_in) begin
                // Pulse ongoing
                if (count < {CNT_WIDTH{1'b1}})
                    count <= count + 1;
            end else if (prev_pulse && !pulse_in) begin
                // Falling edge - check width
                pulse_out <= (count >= MIN_WIDTH && count <= MAX_WIDTH);
                count <= 0;
            end
        end
    end
endmodule
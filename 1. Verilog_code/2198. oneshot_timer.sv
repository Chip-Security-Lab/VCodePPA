module oneshot_timer (
    input wire clock,
    input wire reset,
    input wire trigger,
    input wire [15:0] duration,
    output reg pulse_out
);
    reg [15:0] count;
    reg active;
    reg prev_trigger;
    
    always @(posedge clock) begin
        if (reset) begin
            count <= 16'd0;
            active <= 1'b0;
            pulse_out <= 1'b0;
            prev_trigger <= 1'b0;
        end else begin
            prev_trigger <= trigger;
            
            if (!prev_trigger && trigger) begin
                active <= 1'b1;
                count <= 16'd0;
                pulse_out <= 1'b1;
            end else if (active) begin
                if (count >= duration - 1) begin
                    active <= 1'b0;
                    pulse_out <= 1'b0;
                end else begin
                    count <= count + 1'b1;
                end
            end
        end
    end
endmodule
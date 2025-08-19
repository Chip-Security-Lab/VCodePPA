module oneshot_timer (
    input CLK, RST, TRIGGER,
    input [15:0] PERIOD,
    output reg ACTIVE, DONE
);
    reg [15:0] counter;
    reg trigger_d;
    wire trigger_edge;
    always @(posedge CLK) trigger_d <= TRIGGER;
    assign trigger_edge = TRIGGER & ~trigger_d;
    always @(posedge CLK) begin
        if (RST) begin counter <= 16'd0; ACTIVE <= 1'b0; DONE <= 1'b0; end
        else begin
            DONE <= 1'b0;
            if (trigger_edge && !ACTIVE) begin ACTIVE <= 1'b1; counter <= 16'd0; end
            if (ACTIVE) begin
                counter <= counter + 16'd1;
                if (counter == PERIOD - 1) begin ACTIVE <= 1'b0; DONE <= 1'b1; end
            end
        end
    end
endmodule
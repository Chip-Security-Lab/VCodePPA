module variable_pulse_gen(
    input CLK,
    input RST,
    input [9:0] PULSE_WIDTH,
    input [9:0] PERIOD,
    output reg PULSE
);
    reg [9:0] counter;
    
    always @(posedge CLK) begin
        if (RST) begin
            counter <= 10'd0;
            PULSE <= 1'b0;
        end else begin
            if (counter < PERIOD) 
                counter <= counter + 10'd1;
            else
                counter <= 10'd0;
                
            if (counter < PULSE_WIDTH)
                PULSE <= 1'b1;
            else
                PULSE <= 1'b0;
        end
    end
endmodule
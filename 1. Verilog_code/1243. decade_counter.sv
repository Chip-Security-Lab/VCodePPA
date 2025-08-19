module decade_counter (
    input wire clk, reset,
    output reg [3:0] counter,
    output wire decade_pulse
);
    assign decade_pulse = (counter == 4'd9);
    
    always @(posedge clk) begin
        if (reset)
            counter <= 4'd0;
        else if (counter == 4'd9)
            counter <= 4'd0;
        else
            counter <= counter + 1'b1;
    end
endmodule
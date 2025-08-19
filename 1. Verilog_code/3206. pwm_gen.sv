module pwm_gen(
    input clk,
    input reset,
    input [7:0] duty,
    output pwm_out
);
    reg [7:0] counter;
    
    always @(posedge clk) begin
        if (reset)
            counter <= 8'h00;
        else
            counter <= counter + 1'b1;
    end
    
    assign pwm_out = (counter < duty) ? 1'b1 : 1'b0;
endmodule
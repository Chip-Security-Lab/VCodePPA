module duty_cycle_clock_gate (
    input  wire clk_in,
    input  wire rst_n,
    input  wire [2:0] duty_ratio,
    output wire clk_out
);
    reg [2:0] phase;
    
    always @(posedge clk_in or negedge rst_n) begin
        if (!rst_n)
            phase <= 3'd0;
        else
            phase <= (phase == 3'd7) ? 3'd0 : phase + 1'b1;
    end
    
    assign clk_out = clk_in & (phase < duty_ratio);
endmodule

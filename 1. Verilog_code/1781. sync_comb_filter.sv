module sync_comb_filter #(
    parameter W = 12,
    parameter DELAY = 8
)(
    input clk, rst_n, enable,
    input [W-1:0] din,
    output reg [W-1:0] dout
);
    reg [W-1:0] delay_line [DELAY-1:0];
    integer i;
    
    always @(posedge clk) begin
        if (!rst_n) begin
            for (i = 0; i < DELAY; i = i + 1)
                delay_line[i] <= 0;
            dout <= 0;
        end else if (enable) begin
            // Shift values in delay line
            for (i = DELAY-1; i > 0; i = i - 1)
                delay_line[i] <= delay_line[i-1];
            delay_line[0] <= din;
            
            // Comb filter: y[n] = x[n] - x[n-DELAY]
            dout <= din - delay_line[DELAY-1];
        end
    end
endmodule

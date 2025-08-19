module Timer_PhaseAdjust (
    input clk, rst_n,
    input [3:0] phase,
    output reg out_pulse
);
    reg [3:0] cnt;
    
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            cnt <= 4'h0;
            out_pulse <= 1'b0;
        end else begin
            cnt <= cnt + 4'h1;
            out_pulse <= (cnt == phase);
        end
    end
endmodule
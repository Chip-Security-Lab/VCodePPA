module PulseFilter #(parameter TIMEOUT=8) (
    input clk, rst,
    input in_pulse,
    output reg out_pulse
);
    reg [3:0] cnt;
    always @(posedge clk or posedge rst) begin
        if(rst) {cnt,out_pulse} <= 0;
        else if(in_pulse) begin
            cnt <= TIMEOUT;
            out_pulse <= 1;
        end else begin
            cnt <= (cnt > 0) ? cnt-1 : 0;
            out_pulse <= (cnt != 0);
        end
    end
endmodule
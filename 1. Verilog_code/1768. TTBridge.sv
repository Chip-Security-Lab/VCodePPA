module TTBridge #(
    parameter SCHEDULE = 32'h0000_FFFF
)(
    input clk, rst_n,
    input [31:0] timestamp,
    output reg trigger
);
    reg [31:0] last_ts;

    always @(posedge clk) begin
        if ((timestamp & SCHEDULE) && 
           ((timestamp - last_ts) >= 100)) begin
            trigger <= 1;
            last_ts <= timestamp;
        end else begin
            trigger <= 0;
        end
    end
endmodule
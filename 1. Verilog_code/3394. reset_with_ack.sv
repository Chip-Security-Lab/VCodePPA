module reset_with_ack(
    input wire clk,
    input wire reset_req,
    input wire [3:0] ack_signals,
    output reg [3:0] reset_out,
    output reg reset_complete
);
    always @(posedge clk) begin
        if (reset_req) begin
            reset_out <= 4'hF;
            reset_complete <= 1'b0;
        end else if (ack_signals == 4'hF) begin
            reset_out <= 4'h0;
            reset_complete <= 1'b1;
        end
    end
endmodule

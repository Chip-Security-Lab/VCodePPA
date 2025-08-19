module wave9_pwm #(
    parameter WIDTH = 8
)(
    input  wire             clk,
    input  wire             rst,
    input  wire [WIDTH-1:0] duty,
    output reg              pwm_out
);
    reg [WIDTH-1:0] cnt;

    always @(posedge clk or posedge rst) begin
        if(rst) begin
            cnt     <= 0;
            pwm_out <= 0;
        end else begin
            cnt <= cnt + 1;
            pwm_out <= (cnt < duty) ? 1'b1 : 1'b0;
        end
    end
endmodule

//SystemVerilog
module wave9_pwm #(
    parameter WIDTH = 8
)(
    input  wire             clk,
    input  wire             rst,
    input  wire [WIDTH-1:0] duty,
    output reg              pwm_out
);
    reg [WIDTH-1:0] cnt;
    reg [WIDTH-1:0] cnt_buf1; // Buffer register for cnt
    reg [WIDTH-1:0] cnt_buf2; // Additional buffer for comparison path

    always @(posedge clk or posedge rst) begin
        if(rst) begin
            cnt     <= 0;
            cnt_buf1 <= 0;
            cnt_buf2 <= 0;
            pwm_out <= 0;
        end else begin
            cnt <= cnt + 1;
            cnt_buf1 <= cnt;      // Buffer stage 1
            cnt_buf2 <= cnt_buf1; // Buffer stage 2 for comparison path
            pwm_out <= (cnt_buf2 < duty) ? 1'b1 : 1'b0;
        end
    end
endmodule
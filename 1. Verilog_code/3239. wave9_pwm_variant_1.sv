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
    reg [WIDTH:0] diff;
    wire borrow;

    // 使用条件求和减法算法实现减法器
    always @(*) begin
        diff = {1'b1, ~duty} + {1'b0, cnt} + 1'b1;
    end

    // borrow位指示是否有借位，即cnt < duty
    assign borrow = ~diff[WIDTH];

    always @(posedge clk or posedge rst) begin
        if(rst) begin
            cnt     <= 0;
            pwm_out <= 0;
        end else begin
            cnt <= cnt + 1;
            pwm_out <= borrow ? 1'b1 : 1'b0;
        end
    end
endmodule
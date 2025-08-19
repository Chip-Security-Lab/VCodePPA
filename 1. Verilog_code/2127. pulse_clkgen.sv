module pulse_clkgen #(
    parameter WIDTH = 4
)(
    input wire clk,
    input wire rst,
    output reg pulse
);
    reg [WIDTH-1:0] delay_cnt;
    
    always @(posedge clk) begin
        if (rst) begin
            delay_cnt <= {WIDTH{1'b0}};
            pulse <= 1'b0;
        end else begin
            delay_cnt <= delay_cnt + 1'b1;
            pulse <= (delay_cnt == {WIDTH{1'b1}}) ? 1'b1 : 1'b0;
        end
    end
endmodule
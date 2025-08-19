//SystemVerilog
module TimeDivMux #(parameter DW=8) (
    input wire clk,
    input wire rst,
    input wire [3:0][DW-1:0] ch,
    output reg [DW-1:0] out
);
    reg [1:0] cnt;

    always @(posedge clk or posedge rst) begin
        if (rst) begin
            cnt <= 2'b00;
            out <= {DW{1'b0}};
        end else begin
            cnt <= cnt + 2'b01;
            out <= ch[cnt];
        end
    end
endmodule
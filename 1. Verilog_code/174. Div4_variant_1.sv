//SystemVerilog
module Div4(
    input [7:0] D, d,
    output [7:0] Q, R
);
    reg [8:0] R_temp;
    reg [7:0] Q_temp;
    reg [8:0] borrow;
    integer i;

    always @(*) begin
        R_temp = {1'b0, D};
        Q_temp = 0;
        borrow = 0;

        for(i=0; i<8; i=i+1) begin
            R_temp = {R_temp[7:0], 1'b0};
            borrow = {1'b0, d};
            Q_temp[7-i] = (R_temp[8:1] >= borrow) ? 1'b1 : 1'b0;
            R_temp = (R_temp[8:1] >= borrow) ? (R_temp - borrow) : R_temp;
        end
    end

    assign Q = Q_temp;
    assign R = R_temp[7:0];
endmodule
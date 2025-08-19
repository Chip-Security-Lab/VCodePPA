module Div4(
    input [7:0] D, d,
    output [7:0] Q, R
);
    reg [8:0] R_temp;
    reg [7:0] Q_temp;
    integer i;
    
    always @(*) begin
        R_temp = D;
        Q_temp = 0;
        for(i=0; i<8; i=i+1) begin
            R_temp = {R_temp[7:0], 1'b0};
            if(R_temp[8:4] >= d) begin
                R_temp = R_temp - {d, 1'b0};
                Q_temp[7-i] = 1'b1;
            end
        end
    end
    
    assign Q = Q_temp;
    assign R = R_temp[7:0] >> 1;
endmodule
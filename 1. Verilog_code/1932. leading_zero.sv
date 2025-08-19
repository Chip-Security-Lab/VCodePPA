module leading_zero #(parameter DW=8) (
    input [DW-1:0] data,
    output reg [$clog2(DW+1)-1:0] count
);
    integer i;
    always @* begin
        count = DW;
        for(i=DW-1; i>=0; i=i-1)
            if(data[i]) count = DW-1 - i;
    end
endmodule

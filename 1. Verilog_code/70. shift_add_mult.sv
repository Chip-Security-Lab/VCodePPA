module shift_add_mult (
    input [7:0] mplier, mcand,
    output [15:0] result
);
    reg [15:0] accum;
    integer i;
    
    always @(*) begin
        accum = 16'b0;
        for(i=0; i<8; i=i+1) begin
            if(mplier[i]) accum = accum + (mcand << i);
        end
    end
    assign result = accum;
endmodule

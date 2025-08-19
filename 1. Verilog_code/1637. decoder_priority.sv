module decoder_priority #(WIDTH=4) (
    input [WIDTH-1:0] req,
    output reg [$clog2(WIDTH)-1:0] grant
);
integer i;
always @* begin
    grant = 0;
    for(i=0; i<WIDTH; i=i+1)
        if(req[i]) grant = i;
end
endmodule
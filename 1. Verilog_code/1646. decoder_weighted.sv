module decoder_weighted #(WIDTH=4, WEIGHTS={4,3,2,1}) (
    input [WIDTH-1:0] req,
    output reg [WIDTH-1:0] grant
);
integer i;
always @* begin
    grant = 0;
    for(i=0; i<WIDTH; i=i+1) begin
        if(req[i] && (WEIGHTS[i] > WEIGHTS[grant])) 
            grant = i;
    end
end
endmodule
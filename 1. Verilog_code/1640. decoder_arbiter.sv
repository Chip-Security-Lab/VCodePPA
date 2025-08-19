module decoder_arbiter #(NUM_MASTERS=2) (
    input [NUM_MASTERS-1:0] req,
    output reg [NUM_MASTERS-1:0] grant
);
always @* begin
    grant = req & (~req + 1);
end
endmodule
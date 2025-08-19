module decoder_hier #(parameter NUM_SLAVES=4) (
    input [7:0] addr,
    output reg [3:0] high_decode,
    output reg [3:0] low_decode
);
always @* begin
    high_decode = (addr[7:4] < NUM_SLAVES) ? (1 << addr[7:4]) : 4'b0;
    low_decode = 1 << addr[3:0];
end
endmodule
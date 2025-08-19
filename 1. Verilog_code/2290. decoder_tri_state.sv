module decoder_tri_state (
    input oe,
    input [2:0] addr,
    output reg [7:0] bus
);
    always @(*) 
        bus = oe ? (8'h01 << addr) : 8'hZZ;
endmodule
module struct_unpack #(parameter TOTAL_W=32, FIELD_N=4) (
    input [TOTAL_W-1:0] packed_data,
    input [$clog2(FIELD_N)-1:0] select,
    output reg [TOTAL_W/FIELD_N-1:0] unpacked
);
localparam FIELD_W = TOTAL_W / FIELD_N;
always @(*) begin
    unpacked = packed_data[select*FIELD_W +: FIELD_W];
end
endmodule
module mux_based_shifter (
    input [7:0] data,
    input [2:0] shift,
    output [7:0] result
);
wire [7:0] stage1 = shift[0] ? {data[6:0], data[7]} : data;
wire [7:0] stage2 = shift[1] ? {stage1[5:0], stage1[7:6]} : stage1;
assign result = shift[2] ? {stage2[3:0], stage2[7:4]} : stage2;
endmodule
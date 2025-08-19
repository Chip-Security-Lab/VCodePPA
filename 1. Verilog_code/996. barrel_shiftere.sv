module barrel_shifter(
    input [15:0] din,
    input [3:0] shamt,
    input dir,              // Direction: 0=right, 1=left
    output [15:0] dout
);
    wire [15:0] stage1, stage2, stage3;
    assign stage1 = shamt[0] ? (dir ? {din[14:0], din[15]} : {din[0], din[15:1]}) : din;
    assign stage2 = shamt[1] ? (dir ? {stage1[13:0], stage1[15:14]} : {stage1[1:0], stage1[15:2]}) : stage1;
    assign stage3 = shamt[2] ? (dir ? {stage2[11:0], stage2[15:12]} : {stage2[3:0], stage2[15:4]}) : stage2;
    assign dout = shamt[3] ? (dir ? {stage3[7:0], stage3[15:8]} : {stage3[7:0], stage3[15:8]}) : stage3;
endmodule
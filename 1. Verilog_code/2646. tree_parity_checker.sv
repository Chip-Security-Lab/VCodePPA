module tree_parity_checker (
    input [31:0] data,
    output parity
);
wire [15:0] stage1 = data[31:16] ^ data[15:0];
wire [7:0]  stage2 = stage1[15:8] ^ stage1[7:0];
wire [3:0]  stage3 = stage2[7:4] ^ stage2[3:0];
wire [1:0]  stage4 = stage3[3:2] ^ stage3[1:0];
assign parity = stage4[1] ^ stage4[0];
endmodule
module IVMU_BinaryTree #(parameter W=8) (
    input [W-1:0] req,
    output [2:0] grant
);
wire [3:0] l1 = req[7:4] | req[3:0];
wire [1:0] l2 = l1[3:2] | l1[1:0];
assign grant = req[7] ? 3'h7 : 
              req[6] ? 3'h6 : 
              req[5] ? 3'h5 : 3'h0;
endmodule

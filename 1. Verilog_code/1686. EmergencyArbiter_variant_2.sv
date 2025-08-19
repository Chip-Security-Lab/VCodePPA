//SystemVerilog
module EmergencyArbiter (
    input clk, rst,
    input [3:0] req,
    input emergency,
    output reg [3:0] grant
);

// 组合逻辑部分
wire [3:0] borrow;
wire [3:0] diff;
wire [3:0] grant_next;

// 借位减法器实现
assign borrow[0] = 1'b0;
assign diff[0] = req[0] ^ borrow[0];
assign borrow[1] = ~req[0] & borrow[0];
assign diff[1] = req[1] ^ borrow[1];
assign borrow[2] = ~req[1] & borrow[1];
assign diff[2] = req[2] ^ borrow[2];
assign borrow[3] = ~req[2] & borrow[2];
assign diff[3] = req[3] ^ borrow[3];

// 仲裁逻辑
assign grant_next = emergency ? 4'b1000 : (req & diff);

// 时序逻辑部分
always @(posedge clk) begin
    grant <= grant_next;
end

endmodule
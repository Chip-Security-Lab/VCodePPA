//SystemVerilog
// IEEE 1364-2005 Verilog standard
module RingShiftComb #(parameter RING_SIZE=5) (
    input wire clk, rotate,
    output reg [RING_SIZE-1:0] ring_out
);

wire [RING_SIZE-1:0] ring_next;

// 优化比较逻辑：使用更高效的右移操作实现环形移位
assign ring_next = rotate ? {ring_out[0], ring_out[RING_SIZE-1:1]} : ring_out;

// 使用非阻塞赋值并优化条件检测
always @(posedge clk) begin
    ring_out <= (|ring_out) ? ring_next : {{(RING_SIZE-1){1'b0}}, 1'b1};
end

endmodule
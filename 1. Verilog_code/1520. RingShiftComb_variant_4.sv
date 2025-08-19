//SystemVerilog
// IEEE 1364-2005 compliant
module RingShiftComb #(parameter RING_SIZE=5) (
    input clk, rotate,
    output wire [RING_SIZE-1:0] ring_out
);
    reg [RING_SIZE-1:0] ring_reg = 5'b10000;
    reg [RING_SIZE-1:0] ring_buf = 5'b10000; // Buffer register to reduce fanout

    // Combined always block for both ring shift and buffer update
    always @(posedge clk) begin
        ring_reg <= rotate ? {ring_reg[0], ring_reg[RING_SIZE-1:1]} : ring_reg;
        ring_buf <= ring_reg;
    end

    // Use buffered version to drive outputs
    assign ring_out = ring_buf;
endmodule
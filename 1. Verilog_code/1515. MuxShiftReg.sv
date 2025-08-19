module MuxShiftReg #(parameter DEPTH=4, WIDTH=8) (
    input clk,
    input [1:0] sel,
    input [WIDTH-1:0] din,
    output reg [WIDTH-1:0] dout
);
reg [WIDTH-1:0] regs [0:DEPTH-1];
integer i;

always @(posedge clk) begin
    case(sel)
        2'b00: begin  // Shift left: load at regs[0], shift others left
            for (i=DEPTH-1; i>0; i=i-1)
                regs[i] <= regs[i-1];
            regs[0] <= din;
        end
        2'b01: begin  // Shift right: load at regs[DEPTH-1], shift others right
            for (i=0; i<DEPTH-1; i=i+1)
                regs[i] <= regs[i+1];
            regs[DEPTH-1] <= din;
        end
        2'b10: begin  // Rotate right with regs[0] at front
            for (i=0; i<DEPTH-1; i=i+1)
                regs[i] <= regs[i+1];
            regs[DEPTH-1] <= regs[0];
        end
        default: begin // Hold values
            for (i=0; i<DEPTH; i=i+1)
                regs[i] <= regs[i];
        end
    endcase
    dout <= regs[DEPTH-1];
end
endmodule
//SystemVerilog
// IEEE 1364-2005 (SystemVerilog)
module MuxShiftReg #(parameter DEPTH=4, WIDTH=8) (
    input clk,
    input [1:0] sel,
    input [WIDTH-1:0] din,
    output reg [WIDTH-1:0] dout
);

reg [WIDTH-1:0] regs [0:DEPTH-1];
reg [1:0] sel_reg, sel_pipe;
reg [WIDTH-1:0] din_reg, din_pipe;
reg [WIDTH-1:0] regs_pipe [0:DEPTH-1];
reg [WIDTH-1:0] regs_next [0:DEPTH-1];
integer i;

// Input pipeline stage
always @(posedge clk) begin
    sel_reg <= sel;
    din_reg <= din;
end

// First-level combinational logic with pipeline register
always @(*) begin
    // Save current register state to intermediate pipeline
    for (i=0; i<DEPTH; i=i+1)
        regs_pipe[i] = regs[i];
    
    // Pass through control signals
    sel_pipe = sel_reg;
    din_pipe = din_reg;
end

// Second-level combinational logic for next state
always @(*) begin
    case(sel_pipe)
        2'b00: begin  // Shift left
            for (i=DEPTH-1; i>0; i=i-1)
                regs_next[i] = regs_pipe[i-1];
            regs_next[0] = din_pipe;
        end
        2'b01: begin  // Shift right
            for (i=0; i<DEPTH-1; i=i+1)
                regs_next[i] = regs_pipe[i+1];
            regs_next[DEPTH-1] = din_pipe;
        end
        2'b10: begin  // Rotate right
            for (i=0; i<DEPTH-1; i=i+1)
                regs_next[i] = regs_pipe[i+1];
            regs_next[DEPTH-1] = regs_pipe[0];
        end
        default: begin // Hold values
            for (i=0; i<DEPTH; i=i+1)
                regs_next[i] = regs_pipe[i];
        end
    endcase
end

// Pipeline registers for intermediate values
always @(posedge clk) begin
    for (i=0; i<DEPTH; i=i+1)
        regs_pipe[i] <= regs[i];
    sel_pipe <= sel_reg;
    din_pipe <= din_reg;
end

// Register update stage
always @(posedge clk) begin
    for (i=0; i<DEPTH; i=i+1)
        regs[i] <= regs_next[i];
    dout <= regs_next[DEPTH-1];
end

endmodule
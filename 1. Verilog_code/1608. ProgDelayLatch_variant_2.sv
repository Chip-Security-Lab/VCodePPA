//SystemVerilog
// Top level module
module ProgDelayLatch #(
    parameter DW = 8
)(
    input clk,
    input [DW-1:0] din,
    input [3:0] delay,
    output [DW-1:0] dout
);

wire [DW-1:0] delay_out [0:15];

DelayLine #(
    .DW(DW),
    .DEPTH(16)
) delay_line_inst (
    .clk(clk),
    .din(din),
    .dout(delay_out)
);

DelaySelector #(
    .DW(DW)
) delay_sel_inst (
    .delay_in(delay_out),
    .sel(delay),
    .dout(dout)
);

endmodule

// Delay line submodule with carry lookahead subtractor
module DelayLine #(
    parameter DW = 8,
    parameter DEPTH = 16
)(
    input clk,
    input [DW-1:0] din,
    output [DW-1:0] dout [0:DEPTH-1]
);

reg [DW-1:0] delay_regs [0:DEPTH-1];
wire [DW-1:0] sub_result;
wire [DW:0] carry;

// Carry lookahead subtractor
assign carry[0] = 1'b1; // Initial borrow
genvar i;
generate
    for(i=0; i<DW; i=i+1) begin: gen_sub
        wire g = ~din[i];
        wire p = delay_regs[0][i];
        wire c = carry[i];
        
        assign sub_result[i] = p ^ din[i] ^ c;
        assign carry[i+1] = g | (p & c);
    end
endgenerate

integer j;
always @(posedge clk) begin
    delay_regs[0] <= sub_result;
    for(j=1; j<DEPTH; j=j+1)
        delay_regs[j] <= delay_regs[j-1];
end

genvar k;
generate
    for(k=0; k<DEPTH; k=k+1) begin: gen_delay
        assign dout[k] = delay_regs[k];
    end
endgenerate

endmodule

// Delay selector submodule
module DelaySelector #(
    parameter DW = 8
)(
    input [DW-1:0] delay_in [0:15],
    input [3:0] sel,
    output reg [DW-1:0] dout
);

always @(*) begin
    dout = delay_in[sel];
end

endmodule
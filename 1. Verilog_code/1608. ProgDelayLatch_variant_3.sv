//SystemVerilog
// Delay line submodule
module DelayLine #(
    parameter DW = 8,
    parameter DEPTH = 16
)(
    input clk,
    input [DW-1:0] din,
    output [DW-1:0] delay_out [0:DEPTH-1]
);

reg [DW-1:0] delay_regs [0:DEPTH-1];

// First stage
always @(posedge clk) begin
    delay_regs[0] <= din;
end

// Middle stages
genvar i;
generate
    for(i=1; i<DEPTH; i=i+1) begin: delay_stages
        always @(posedge clk) begin
            delay_regs[i] <= delay_regs[i-1];
        end
    end
endgenerate

// Output assignment
genvar j;
generate
    for(j=0; j<DEPTH; j=j+1) begin: output_assign
        assign delay_out[j] = delay_regs[j];
    end
endgenerate

endmodule

// Output selector submodule
module OutputSelector #(
    parameter DW = 8,
    parameter SEL_WIDTH = 4
)(
    input clk,
    input [DW-1:0] delay_in [0:(1<<SEL_WIDTH)-1],
    input [SEL_WIDTH-1:0] sel,
    output reg [DW-1:0] dout
);

always @(posedge clk) begin
    dout <= delay_in[sel];
end

endmodule

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
    .delay_out(delay_out)
);

OutputSelector #(
    .DW(DW),
    .SEL_WIDTH(4)
) output_sel_inst (
    .clk(clk),
    .delay_in(delay_out),
    .sel(delay),
    .dout(dout)
);

endmodule
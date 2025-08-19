module pipeline_regfile #(
    parameter DW = 64,
    parameter AW = 3,
    parameter DEPTH = 8
)(
    input clk,
    input rst,
    input wr_en,
    input [AW-1:0] addr,
    input [DW-1:0] din,
    output [DW-1:0] dout
);
reg [DW-1:0] mem [0:DEPTH-1];
reg [DW-1:0] pipe_reg1, pipe_reg2;
integer i;

always @(posedge clk) begin
    if (rst) begin
        for (i=0; i<DEPTH; i=i+1) mem[i] <= {DW{1'b0}};
        pipe_reg1 <= {DW{1'b0}};
        pipe_reg2 <= {DW{1'b0}};
    end else begin
        if (wr_en) mem[addr] <= din;
        pipe_reg1 <= mem[addr];
        pipe_reg2 <= pipe_reg1;
    end
end

assign dout = pipe_reg2;
endmodule
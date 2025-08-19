module FlowCtrlShift #(parameter DEPTH=4, DW=8) (
    input clk, rstn, valid_in, ready_out,
    output valid_out, ready_in,
    input [DW-1:0] data_in,
    output [DW-1:0] data_out
);
reg [DW-1:0] pipe [0:DEPTH-1];
reg [DEPTH-1:0] valid_pipe;
integer i;

assign ready_in = !valid_pipe[DEPTH-1] || ready_out;
assign valid_out = valid_pipe[DEPTH-1];
assign data_out = pipe[DEPTH-1];

always @(posedge clk or negedge rstn) begin
    if (!rstn) begin
        valid_pipe <= 0;
        for (i=0; i<DEPTH; i=i+1)
            pipe[i] <= 0;
    end else if (ready_in) begin
        // Shift the pipeline
        for (i=DEPTH-1; i>0; i=i-1) begin
            pipe[i] <= pipe[i-1];
            valid_pipe[i] <= valid_pipe[i-1];
        end
        pipe[0] <= data_in;
        valid_pipe[0] <= valid_in;
    end
end
endmodule
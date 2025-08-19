module pipe_prefetch_buf #(parameter DW=32) (
    input clk, en,
    input [DW-1:0] data_in,
    output [DW-1:0] data_out
);
    reg [DW-1:0] stage[0:2];
    always @(posedge clk) if(en) begin
        stage[0] <= data_in;
        stage[1] <= stage[0];
        stage[2] <= stage[1];
    end
    assign data_out = stage[2];
endmodule

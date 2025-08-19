module clk_gate_pipeline #(parameter STAGES=3) (
    input clk, en, in,
    output reg out
);
reg [STAGES:0] pipe;
always @(posedge clk) begin
    if(en) pipe <= {pipe[STAGES-1:0], in};
    out <= pipe[STAGES];
end
endmodule
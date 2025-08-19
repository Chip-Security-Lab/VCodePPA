//SystemVerilog
module clk_gate_pipeline #(parameter STAGES=2) (
    input clk, en, in,
    output reg out
);
    reg [STAGES-1:0] pipe;
    
    always @(posedge clk) begin
        if(en) begin
            pipe <= {pipe[STAGES-2:0], in};
            out <= pipe[STAGES-1];
        end
    end
endmodule
module clk_gate_fsm (
    input clk, rst, en,
    output reg [1:0] state
);
parameter S0=0, S1=1, S2=2;
always @(posedge clk) begin
    if(rst) state <= S0;
    else if(en) begin
        case(state)
            S0: state <= S1;
            S1: state <= S2;
            S2: state <= S0;
        endcase
    end
end
endmodule
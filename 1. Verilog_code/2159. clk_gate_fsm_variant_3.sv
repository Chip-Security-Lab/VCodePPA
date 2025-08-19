//SystemVerilog
module clk_gate_fsm (
    input clk, rst, en,
    output reg [1:0] state
);
    parameter S0=0, S1=1, S2=2;
    
    always @(posedge clk) begin
        state <= rst ? S0 : 
                 (en ? (state == S0 ? S1 : 
                        state == S1 ? S2 : S0) : 
                       state);
    end
endmodule
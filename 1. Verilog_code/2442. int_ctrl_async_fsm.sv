module int_ctrl_async_fsm #(DW=4)(
    input clk, en,
    input [DW-1:0] int_req,
    output reg int_valid
);
reg [1:0] state;
always @(posedge clk) begin
    if(en) case(state)
        0: if(|int_req) state <= 1;
        1: begin int_valid <= 1; state <= 2; end
        2: state <= 0;
    endcase
end
endmodule
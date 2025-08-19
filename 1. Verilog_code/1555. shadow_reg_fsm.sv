module shadow_reg_fsm #(parameter DW=4) (
    input clk, rst, trigger,
    input [DW-1:0] data_in,
    output reg [DW-1:0] data_out
);
    reg [DW-1:0] shadow;
    reg state;
    always @(posedge clk) begin
        if(rst) {state, shadow} <= 0;
        else case(state)
            0: if(trigger) begin
                shadow <= data_in;
                state <= 1;
            end
            1: begin
                data_out <= shadow;
                state <= 0;
            end
        endcase
    end
endmodule
module counter_onehot #(parameter BITS=4) (
    input clk, rst,
    output reg [BITS-1:0] state
);
always @(posedge clk) begin
    if (rst) state <= 1;
    else state <= {state[BITS-2:0], state[BITS-1]};
end
endmodule
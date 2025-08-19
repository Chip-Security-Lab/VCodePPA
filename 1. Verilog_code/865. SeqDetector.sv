module SeqDetector #(parameter PATTERN=4'b1101) (
    input clk, rst_n,
    input data_in,
    output reg detected
);
reg [3:0] state;
always @(posedge clk or negedge rst_n) begin
    if (!rst_n) state <= 0;
    else state <= {state[2:0], data_in};
    detected <= (state == PATTERN);
end
endmodule

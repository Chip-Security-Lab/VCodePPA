module pause_enabled_ring (
    input clk, pause, rst,
    output reg [3:0] current_state
);
always @(posedge clk) begin
    if (rst) current_state <= 4'b0001;
    else if (!pause) current_state <= {current_state[0], current_state[3:1]};
end
endmodule

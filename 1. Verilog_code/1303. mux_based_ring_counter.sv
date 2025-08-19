module mux_based_ring_counter (
    input clk, reset,
    output reg [3:0] state
);
always @(posedge clk) begin
    case(state)
        4'b0001: state <= 4'b0010;
        4'b0010: state <= 4'b0100;
        4'b0100: state <= 4'b1000;
        4'b1000: state <= 4'b0001;
        default: state <= 4'b0001;
    endcase
    if (reset) state <= 4'b0001;
end
endmodule

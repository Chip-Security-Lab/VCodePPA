module RangeDetector_WindowFSM #(
    parameter WIDTH = 8
)(
    input clk, rst_n,
    input [WIDTH-1:0] data_in,
    input [WIDTH-1:0] win_low,
    input [WIDTH-1:0] win_high,
    output reg cross_event
);
// 使用localparam替代SystemVerilog的typedef enum
localparam INSIDE = 1'b0;
localparam OUTSIDE = 1'b1;

reg current_state, next_state;

always @(posedge clk or negedge rst_n) begin
    if(!rst_n) 
        current_state <= INSIDE;
    else 
        current_state <= next_state;
end

always @(*) begin
    case(current_state)
        INSIDE:  next_state = (data_in < win_low || data_in > win_high) ? OUTSIDE : INSIDE;
        OUTSIDE: next_state = (data_in >= win_low && data_in <= win_high) ? INSIDE : OUTSIDE;
        default: next_state = INSIDE;
    endcase
end

always @(posedge clk) begin
    cross_event <= (current_state != next_state);
end
endmodule
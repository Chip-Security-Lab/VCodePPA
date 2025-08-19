module subtractor_core (
    input wire [7:0] x,
    input wire [7:0] y,
    output reg [7:0] result
);

always @(*) begin
    result = x - y;
end

endmodule

module subtractor_task (
    input wire clk,
    input wire [7:0] a,
    input wire [7:0] b,
    output reg [7:0] res
);

wire [7:0] sub_result;

subtractor_core sub_core (
    .x(a),
    .y(b),
    .result(sub_result)
);

always @(posedge clk) begin
    res <= sub_result;
end

endmodule
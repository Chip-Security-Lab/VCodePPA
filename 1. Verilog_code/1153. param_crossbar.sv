module param_crossbar #(
    parameter PORTS = 4,
    parameter WIDTH = 8
)(
    input wire clock, reset,
    input wire [WIDTH-1:0] in [0:PORTS-1],
    input wire [$clog2(PORTS)-1:0] sel [0:PORTS-1],
    input wire enable,
    output reg [WIDTH-1:0] out [0:PORTS-1]
);
    // Flexible crossbar with configurable ports and widths
    integer i, j;
    always @(posedge clock) begin
        if (reset) begin
            for (i = 0; i < PORTS; i = i + 1)
                out[i] <= {WIDTH{1'b0}};
        end else if (enable) begin
            for (i = 0; i < PORTS; i = i + 1)
                out[i] <= in[sel[i]];
        end
    end
endmodule
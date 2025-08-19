module right_logical_shifter #(
    parameter WIDTH = 16
)(
    input wire clock, reset, enable,
    input wire [WIDTH-1:0] in_data,
    input wire [$clog2(WIDTH)-1:0] shift_amount,
    output reg [WIDTH-1:0] out_data
);
    always @(posedge clock) begin
        if (reset) out_data <= {WIDTH{1'b0}};
        else if (enable) out_data <= in_data >> shift_amount;
    end
endmodule
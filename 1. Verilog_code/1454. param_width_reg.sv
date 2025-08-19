module param_width_reg #(
    parameter WIDTH = 32
)(
    input clk, reset,
    input [WIDTH-1:0] data_input,
    input enable,
    output reg [WIDTH-1:0] data_output
);
    always @(posedge clk) begin
        if (reset)
            data_output <= {WIDTH{1'b0}};
        else if (enable)
            data_output <= data_input;
    end
endmodule
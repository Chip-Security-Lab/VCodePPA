module param_reset_ctrl #(
    parameter WIDTH = 4,
    parameter ACTIVE_HIGH = 1
)(
    input wire reset_in,
    input wire enable,
    output wire [WIDTH-1:0] reset_out
);
    wire reset_val = ACTIVE_HIGH ? reset_in : ~reset_in;
    assign reset_out = enable ? {WIDTH{reset_val}} : {WIDTH{1'b0}};
endmodule
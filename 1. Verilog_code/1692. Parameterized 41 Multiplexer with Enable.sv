module param_mux_4to1 #(
    parameter WIDTH = 16
)(
    input [WIDTH-1:0] in0, in1, in2, in3,
    input [1:0] select,
    input enable,
    output reg [WIDTH-1:0] dout
);
    always @(*) begin
        dout = {WIDTH{1'b0}};
        if (enable)
            case (select)
                2'b00: dout = in0;
                2'b01: dout = in1;
                2'b10: dout = in2;
                2'b11: dout = in3;
            endcase
    end
endmodule
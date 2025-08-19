//SystemVerilog
module param_mux_4to1 #(
    parameter WIDTH = 16
)(
    input [WIDTH-1:0] in0, in1, in2, in3,
    input [1:0] select,
    input enable,
    output reg [WIDTH-1:0] dout
);
    always @(*) begin
        case ({enable, select})
            3'b000: dout = {WIDTH{1'b0}};
            3'b001: dout = {WIDTH{1'b0}};
            3'b010: dout = {WIDTH{1'b0}};
            3'b011: dout = {WIDTH{1'b0}};
            3'b100: dout = in0;
            3'b101: dout = in1;
            3'b110: dout = in2;
            3'b111: dout = in3;
        endcase
    end
endmodule
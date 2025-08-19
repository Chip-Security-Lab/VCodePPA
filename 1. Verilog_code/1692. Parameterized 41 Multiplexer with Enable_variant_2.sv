//SystemVerilog
module param_mux_4to1 #(
    parameter WIDTH = 16
)(
    input [WIDTH-1:0] in0, in1, in2, in3,
    input [1:0] select,
    input enable,
    output reg [WIDTH-1:0] dout
);

    // 使用补码加法实现减法器
    wire [WIDTH-1:0] in0_comp = ~in0 + 1'b1;
    wire [WIDTH-1:0] in1_comp = ~in1 + 1'b1;
    wire [WIDTH-1:0] in2_comp = ~in2 + 1'b1;
    wire [WIDTH-1:0] in3_comp = ~in3 + 1'b1;

    always @(*) begin
        dout = {WIDTH{1'b0}};
        if (enable) begin
            case(select)
                2'b00: dout = in0_comp;
                2'b01: dout = in1_comp;
                2'b10: dout = in2_comp;
                2'b11: dout = in3_comp;
                default: dout = {WIDTH{1'b0}};
            endcase
        end
    end

endmodule
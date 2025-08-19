module rom_param_init #(
    parameter INIT_VAL = 64'h1234_5678_9ABC_DEF0
)(
    input [2:0] adr,
    output reg [15:0] dat
);
    // 使用case语句替代移位运算，更容易综合
    always @(*) begin
        case(adr)
            3'b000: dat = INIT_VAL[15:0];
            3'b001: dat = INIT_VAL[31:16];
            3'b010: dat = INIT_VAL[47:32];
            3'b011: dat = INIT_VAL[63:48];
            default: dat = 16'h0000;
        endcase
    end
endmodule
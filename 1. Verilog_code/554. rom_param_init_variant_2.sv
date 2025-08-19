//SystemVerilog
module rom_param_init #(
    parameter INIT_VAL = 64'h1234_5678_9ABC_DEF0
)(
    input [2:0] adr,
    output reg [15:0] dat
);
    // 使用if-else级联结构替代case语句
    always @(*) begin
        if (adr == 3'b000) begin
            dat = INIT_VAL[15:0];
        end
        else if (adr == 3'b001) begin
            dat = INIT_VAL[31:16];
        end
        else if (adr == 3'b010) begin
            dat = INIT_VAL[47:32];
        end
        else if (adr == 3'b011) begin
            dat = INIT_VAL[63:48];
        end
        else begin
            dat = 16'h0000;
        end
    end
endmodule
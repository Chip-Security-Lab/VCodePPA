//SystemVerilog
module rom_lut #(parameter OUT=24)(
    input [3:0] sel,
    output reg [OUT-1:0] value
);
    // 使用组合逻辑实现查找表功能
    always @(*) begin
        case(sel[3:2])
            2'b00: value = 24'h000000;
            2'b01: value = 24'h000100;
            2'b10: value = 24'h001000;
            2'b11: value = 24'h008000;
            default: value = 24'h000000;
        endcase
        
        case(sel[1:0])
            2'b00: value = value | 24'h000001;
            2'b01: value = value | 24'h000002;
            2'b10: value = value | 24'h000004;
            2'b11: value = value | 24'h000008;
            default: value = value | 24'h000000;
        endcase
    end
endmodule
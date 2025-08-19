//SystemVerilog
module rom_lut #(parameter OUT=24)(
    input [3:0] sel,
    output reg [OUT-1:0] value
);
    // 低位部分 (bit 0-7)
    reg [7:0] value_low;
    // 中位部分 (bit 8-15)
    reg [7:0] value_mid;
    // 高位部分 (bit 16-23)
    reg [7:0] value_high;

    // 处理低8位
    always @(*) begin
        case(sel[2:0])
            3'b000: value_low = (sel[3]) ? 8'h00 : 8'h01;
            3'b001: value_low = (sel[3]) ? 8'h00 : 8'h02;
            3'b010: value_low = (sel[3]) ? 8'h00 : 8'h04;
            3'b011: value_low = (sel[3]) ? 8'h00 : 8'h08;
            3'b100: value_low = (sel[3]) ? 8'h00 : 8'h10;
            3'b101: value_low = (sel[3]) ? 8'h00 : 8'h20;
            3'b110: value_low = (sel[3]) ? 8'h00 : 8'h40;
            3'b111: value_low = (sel[3]) ? 8'h00 : 8'h80;
            default: value_low = 8'h00;
        endcase
    end

    // 处理中8位
    always @(*) begin
        case(sel[2:0])
            3'b000: value_mid = (sel[3]) ? 8'h01 : 8'h00;
            3'b001: value_mid = (sel[3]) ? 8'h02 : 8'h00;
            3'b010: value_mid = (sel[3]) ? 8'h04 : 8'h00;
            3'b011: value_mid = (sel[3]) ? 8'h08 : 8'h00;
            3'b100: value_mid = (sel[3]) ? 8'h10 : 8'h00;
            3'b101: value_mid = (sel[3]) ? 8'h20 : 8'h00;
            3'b110: value_mid = (sel[3]) ? 8'h40 : 8'h00;
            3'b111: value_mid = (sel[3]) ? 8'h80 : 8'h00;
            default: value_mid = 8'h00;
        endcase
    end

    // 高位总是0
    always @(*) begin
        value_high = 8'h00;
    end

    // 组合最终输出
    always @(*) begin
        value = {value_high, value_mid, value_low};
    end
endmodule
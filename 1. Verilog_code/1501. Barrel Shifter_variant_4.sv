//SystemVerilog
// IEEE 1364-2005 Verilog标准
module barrel_shifter (
    input wire [7:0] data_in,
    input wire [2:0] shift_amount,
    input wire direction, // 0: right, 1: left
    output reg [7:0] data_out
);
    // 实现桶形移位器
    always @(*) begin
        if (direction) begin
            // 左移桶形移位器实现
            case (shift_amount)
                3'b000: data_out = data_in;
                3'b001: data_out = {data_in[6:0], 1'b0};
                3'b010: data_out = {data_in[5:0], 2'b00};
                3'b011: data_out = {data_in[4:0], 3'b000};
                3'b100: data_out = {data_in[3:0], 4'b0000};
                3'b101: data_out = {data_in[2:0], 5'b00000};
                3'b110: data_out = {data_in[1:0], 6'b000000};
                3'b111: data_out = {data_in[0], 7'b0000000};
            endcase
        end else begin
            // 右移桶形移位器实现
            case (shift_amount)
                3'b000: data_out = data_in;
                3'b001: data_out = {1'b0, data_in[7:1]};
                3'b010: data_out = {2'b00, data_in[7:2]};
                3'b011: data_out = {3'b000, data_in[7:3]};
                3'b100: data_out = {4'b0000, data_in[7:4]};
                3'b101: data_out = {5'b00000, data_in[7:5]};
                3'b110: data_out = {6'b000000, data_in[7:6]};
                3'b111: data_out = {7'b0000000, data_in[7]};
            endcase
        end
    end
endmodule
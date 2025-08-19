//SystemVerilog
module barrel_shifter_4bit (
    input [3:0] data_in,
    input [1:0] shift_amount,
    input direction,  // 0: right, 1: left
    output reg [3:0] data_out
);
    always @(*) begin
        case({direction, shift_amount})
            3'b000: data_out = data_in;
            3'b001: data_out = {data_in[0], data_in[3:1]};
            3'b010: data_out = {data_in[1:0], data_in[3:2]};
            3'b011: data_out = {data_in[2:0], data_in[3]};
            3'b100: data_out = data_in;
            3'b101: data_out = {data_in[2:0], data_in[3]};
            3'b110: data_out = {data_in[1:0], data_in[3:2]};
            3'b111: data_out = {data_in[0], data_in[3:1]};
        endcase
    end
endmodule
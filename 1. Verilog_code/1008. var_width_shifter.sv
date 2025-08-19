module var_width_shifter(
    input wire clk, rst,
    input wire [31:0] data,
    input wire [1:0] width_sel,   // 00:8-bit, 01:16-bit, 10:24-bit, 11:32-bit
    input wire [4:0] shift_amt,
    input wire shift_left,
    output reg [31:0] result
);
    reg [31:0] masked_data;
    always @(*) begin
        case (width_sel)
            2'b00: masked_data = {24'b0, data[7:0]};
            2'b01: masked_data = {16'b0, data[15:0]};
            2'b10: masked_data = {8'b0, data[23:0]};
            default: masked_data = data;
        endcase
    end
    always @(posedge clk) begin
        if (rst) result <= 32'b0;
        else result <= shift_left ? (masked_data << shift_amt) : (masked_data >> shift_amt);
    end
endmodule
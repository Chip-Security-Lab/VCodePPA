module en_rst_shifter (
    input clk, rst, en,
    input [1:0] mode,   // 00: hold, 01: shift left, 10: shift right
    input serial_in,
    output reg [3:0] data
);
    always @(posedge clk) begin
        if (rst)
            data <= 4'b0000;
        else if (en) begin
            case(mode)
                2'b01: data <= {data[2:0], serial_in};  // Left
                2'b10: data <= {serial_in, data[3:1]};  // Right
                default: data <= data;                  // Hold
            endcase
        end
    end
endmodule
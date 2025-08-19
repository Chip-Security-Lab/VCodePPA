module serial_shifter(
    input wire clk, rst_n, enable,
    input wire [1:0] mode,   // 00:hold, 01:left, 10:right, 11:load
    input wire [7:0] data_in,
    input wire serial_in,
    output reg [7:0] data_out
);
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n)
            data_out <= 8'h00;
        else if (enable) begin
            case (mode)
                2'b00: data_out <= data_out;
                2'b01: data_out <= {data_out[6:0], serial_in};
                2'b10: data_out <= {serial_in, data_out[7:1]};
                2'b11: data_out <= data_in;
            endcase
        end
    end
endmodule
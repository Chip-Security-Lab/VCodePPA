//SystemVerilog
module crc_rom (
    input clk,
    input [3:0] addr,
    input req,
    output reg ack,
    output reg [7:0] data,
    output reg crc_error
);
    reg [7:0] rom [0:15];
    reg [3:0] crc [0:15];
    reg [7:0] data_reg;
    reg crc_error_reg;
    reg processing;

    initial begin
        rom[0] = 8'h99; crc[0] = 4'hF;
        ack = 1'b0;
        processing = 1'b0;
    end

    always @(posedge clk) begin
        if (req && !processing) begin
            data_reg <= rom[addr];
            crc_error_reg <= (^rom[addr]) != crc[addr];
            processing <= 1'b1;
            ack <= 1'b1;
        end
        else if (processing) begin
            data <= data_reg;
            crc_error <= crc_error_reg;
            processing <= 1'b0;
            ack <= 1'b0;
        end
    end
endmodule
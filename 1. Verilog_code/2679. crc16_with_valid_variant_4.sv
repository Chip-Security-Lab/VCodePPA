//SystemVerilog
module crc16_with_valid(
    input clk,
    input reset,
    input [7:0] data_in,
    input data_valid,
    output reg [15:0] crc,
    output reg crc_valid
);
    localparam POLY = 16'h1021;
    reg [15:0] crc_next;
    
    always @(posedge clk) begin
        case ({reset, data_valid, crc[15]})
            3'b100, 3'b101: begin  // reset=1, data_valid=0, crc[15]=x
                crc <= 16'hFFFF;
                crc_valid <= 1'b0;
            end
            3'b110: begin  // reset=1, data_valid=1, crc[15]=0
                crc <= 16'hFFFF;
                crc_valid <= 1'b0;
            end
            3'b111: begin  // reset=1, data_valid=1, crc[15]=1
                crc <= 16'hFFFF;
                crc_valid <= 1'b0;
            end
            3'b010: begin  // reset=0, data_valid=1, crc[15]=0
                crc <= {crc[14:0], 1'b0} ^ {8'h00, data_in};
                crc_valid <= 1'b1;
            end
            3'b011: begin  // reset=0, data_valid=1, crc[15]=1
                crc <= {crc[14:0], 1'b0} ^ POLY ^ {8'h00, data_in};
                crc_valid <= 1'b1;
            end
            default: begin  // reset=0, data_valid=0, crc[15]=x
                crc <= crc;
                crc_valid <= 1'b0;
            end
        endcase
    end
endmodule
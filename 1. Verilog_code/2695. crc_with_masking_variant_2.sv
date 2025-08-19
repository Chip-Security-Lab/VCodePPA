//SystemVerilog
module crc_with_masking(
    input wire clk,
    input wire rst,
    input wire [7:0] data,
    input wire [7:0] mask,
    input wire req,
    output reg ack,
    output reg [7:0] crc
);
    parameter [7:0] POLY = 8'h07;
    
    wire [7:0] masked_data = data & mask;
    reg req_reg;
    
    always @(posedge clk) begin
        if (rst) begin
            crc <= 8'h00;
            ack <= 1'b0;
            req_reg <= 1'b0;
        end else begin
            req_reg <= req;
            
            if (req && !req_reg) begin
                // New request detected
                crc <= {crc[6:0], 1'b0} ^ ((crc[7] ^ masked_data[0]) ? POLY : 8'h00);
                ack <= 1'b1;
            end else if (!req && req_reg) begin
                // Request deasserted, clear acknowledge
                ack <= 1'b0;
            end
        end
    end
endmodule
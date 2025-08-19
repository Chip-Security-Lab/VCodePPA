//SystemVerilog
module crc_checker(
    input wire clk,
    input wire rst,
    input wire [7:0] data_in,
    input wire [7:0] crc_in,
    input wire data_req,
    output reg data_ack,
    output reg [7:0] calculated_crc
);
    parameter [7:0] POLY = 8'hD5;
    reg [7:0] next_crc_reg;
    reg crc_match_reg;
    reg req_handled;
    
    wire [7:0] next_crc_comb = {calculated_crc[6:0], 1'b0} ^ 
                              ((calculated_crc[7] ^ data_in[0]) ? POLY : 8'h00);
    
    wire crc_match_comb = (next_crc_reg == crc_in);
    
    always @(posedge clk) begin
        if (rst) begin
            next_crc_reg <= 8'h00;
            crc_match_reg <= 1'b0;
            data_ack <= 1'b0;
            req_handled <= 1'b0;
        end else begin
            if (data_req && !req_handled) begin
                next_crc_reg <= next_crc_comb;
                crc_match_reg <= crc_match_comb;
                data_ack <= crc_match_reg;
                req_handled <= 1'b1;
            end else if (!data_req) begin
                req_handled <= 1'b0;
                data_ack <= 1'b0;
            end
        end
    end

    always @(posedge clk) begin
        if (rst) begin
            calculated_crc <= 8'h00;
        end else begin
            calculated_crc <= next_crc_reg;
        end
    end
endmodule
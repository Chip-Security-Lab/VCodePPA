//SystemVerilog
module basic_crc8(
    input wire clk,
    input wire rst_n,
    input wire [7:0] data_in,
    input wire data_req,
    output reg data_ack,
    output reg [7:0] crc_out
);
    parameter POLY = 8'hD5;
    
    reg req_prev;
    wire req_rise;
    wire [7:0] poly_mask;
    wire [7:0] crc_shift;
    wire [7:0] next_crc;
    
    assign req_rise = data_req && !req_prev;
    assign poly_mask = {8{crc_out[7]}} & POLY;
    assign crc_shift = {crc_out[6:0], 1'b0};
    assign next_crc = crc_shift ^ poly_mask ^ data_in;
    
    always @(posedge clk) begin
        if (!rst_n) begin
            crc_out <= 8'h00;
            data_ack <= 1'b0;
            req_prev <= 1'b0;
        end
        else begin
            req_prev <= data_req;
            
            if (req_rise) begin
                crc_out <= next_crc;
                data_ack <= 1'b1;
            end
            else if (!data_req) begin
                data_ack <= 1'b0;
            end
        end
    end
endmodule
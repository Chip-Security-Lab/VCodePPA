//SystemVerilog
module registered_crc16(
    input wire clk,
    input wire rst,
    input wire [15:0] data_in,
    input wire req,
    output reg ack,
    output reg [15:0] crc_reg_out
);
    localparam [15:0] POLY = 16'h8005;
    reg [15:0] crc_temp;
    reg req_d;
    wire req_posedge;
    wire req_negedge;
    
    // Edge detection logic
    assign req_posedge = req && !req_d;
    assign req_negedge = !req && req_d;
    
    // Request delay register
    always @(posedge clk) begin
        if (rst) begin
            req_d <= 1'b0;
        end else begin
            req_d <= req;
        end
    end
    
    // CRC calculation logic
    always @(posedge clk) begin
        if (rst) begin
            crc_temp <= 16'hFFFF;
            crc_reg_out <= 16'h0000;
        end else if (req_posedge) begin
            crc_temp <= crc_temp ^ data_in;
            crc_reg_out <= crc_temp;
        end
    end
    
    // Acknowledge generation logic
    always @(posedge clk) begin
        if (rst) begin
            ack <= 1'b0;
        end else if (req_posedge) begin
            ack <= 1'b1;
        end else if (req_negedge) begin
            ack <= 1'b0;
        end
    end
endmodule
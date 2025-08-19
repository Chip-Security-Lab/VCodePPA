//SystemVerilog
module registered_crc16(
    input wire clk,
    input wire rst,
    input wire [15:0] data_in,
    input wire valid_in,
    output wire ready_out,
    output reg [15:0] crc_out,
    output reg valid_out
);
    localparam [15:0] POLY = 16'h8005;
    
    reg [15:0] crc_temp;
    reg processing;
    
    assign ready_out = !processing || valid_out;
    
    always @(posedge clk or posedge rst) begin
        if (rst) begin
            crc_temp <= 16'hFFFF;
            crc_out <= 16'h0000;
            valid_out <= 1'b0;
            processing <= 1'b0;
        end else begin
            if (valid_in && ready_out) begin
                crc_temp <= crc_temp ^ data_in;
                processing <= 1'b1;
                valid_out <= 1'b0;
            end
            
            if (processing && !valid_out) begin
                crc_out <= crc_temp;
                valid_out <= 1'b1;
                processing <= 1'b0;
            end else if (valid_out) begin
                valid_out <= 1'b0;
            end
        end
    end
endmodule
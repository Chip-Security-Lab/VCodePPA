//SystemVerilog
module integrity_crc(
    input wire clk,
    input wire rst,
    input wire [7:0] data,
    input wire valid,
    output wire ready,
    output reg [7:0] crc_value,
    output reg integrity_error
);
    parameter [7:0] POLY = 8'hD5;
    parameter [7:0] EXPECTED_CRC = 8'h00;
    
    reg [7:0] shadow_crc;
    reg busy;
    reg [7:0] next_crc;
    reg [7:0] next_shadow_crc;
    wire crc_xor_data;
    wire shadow_xor_data;
    
    // Ready signal generation
    assign ready = !busy;
    
    // Pre-compute XOR operations
    assign crc_xor_data = crc_value[7] ^ data[0];
    assign shadow_xor_data = shadow_crc[7] ^ data[0];
    
    // Pre-compute next CRC values
    always @(*) begin
        next_crc = {crc_value[6:0], 1'b0} ^ (crc_xor_data ? POLY : 8'h00);
        next_shadow_crc = {shadow_crc[6:0], 1'b0} ^ (shadow_xor_data ? POLY : 8'h00);
    end
    
    always @(posedge clk) begin
        if (rst) begin
            crc_value <= 8'h00;
            shadow_crc <= 8'h00;
            integrity_error <= 1'b0;
            busy <= 1'b0;
        end else begin
            if (valid && ready) begin
                // Data transaction happens when both valid and ready are high
                crc_value <= next_crc;
                shadow_crc <= next_shadow_crc;
                integrity_error <= (next_crc != next_shadow_crc);
                
                // Optional: Add busy cycle for improved timing
                busy <= 1'b1;
            end else if (busy) begin
                // Release busy state after one cycle
                busy <= 1'b0;
            end
        end
    end
endmodule
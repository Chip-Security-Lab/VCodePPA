//SystemVerilog
module crc_error_injection (
    input clk, inject_err,
    input [7:0] data_in,
    output reg [15:0] crc
);

    wire [7:0] real_data = inject_err ? ~data_in : data_in;
    
    // Pipeline registers
    reg [7:0] data_pipe;
    reg [15:0] crc_pipe;
    
    // Stage 1: Data preparation and initial CRC calculation
    always @(posedge clk) begin
        data_pipe <= real_data;
        crc_pipe <= crc;
    end
    
    // Stage 2: Final CRC calculation with Brent-Kung adder
    always @(posedge clk) begin
        crc <= crc16_calc_bk(data_pipe, crc_pipe);
    end
    
    // Brent-Kung adder implementation for CRC16 calculation
    function [15:0] crc16_calc_bk;
        input [7:0] data;
        input [15:0] crc_in;
        reg [15:0] crc_out;
        reg [15:0] g, p;
        reg [15:0] carry;
        integer i;
        begin
            crc_out = crc_in;
            
            // Generate and propagate signals
            for (i = 0; i < 8; i = i + 1) begin
                g[i] = (data[i] ^ crc_out[15]) & 1'b1;
                p[i] = (data[i] ^ crc_out[15]) ^ 1'b1;
            end
            
            // Brent-Kung prefix computation
            // Level 1
            for (i = 0; i < 4; i = i + 1) begin
                g[i*2+1] = g[i*2+1] | (p[i*2+1] & g[i*2]);
                p[i*2+1] = p[i*2+1] & p[i*2];
            end
            
            // Level 2
            for (i = 0; i < 2; i = i + 1) begin
                g[i*4+3] = g[i*4+3] | (p[i*4+3] & g[i*4+1]);
                p[i*4+3] = p[i*4+3] & p[i*4+1];
            end
            
            // Level 3
            g[7] = g[7] | (p[7] & g[3]);
            p[7] = p[7] & p[3];
            
            // Final carry computation
            carry[0] = 1'b0;
            for (i = 1; i < 8; i = i + 1) begin
                carry[i] = g[i-1];
            end
            
            // Sum computation
            for (i = 0; i < 8; i = i + 1) begin
                if (carry[i])
                    crc_out = {crc_out[14:0], 1'b0} ^ 16'h8005;
                else
                    crc_out = {crc_out[14:0], 1'b0};
            end
            
            crc16_calc_bk = crc_out;
        end
    endfunction

endmodule
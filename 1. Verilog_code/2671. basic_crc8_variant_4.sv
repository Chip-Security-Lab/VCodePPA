//SystemVerilog
module basic_crc8(
    input wire clk,
    input wire rst_n,
    input wire [7:0] data_in,
    input wire valid,
    output reg ready,
    output reg [7:0] crc_out
);
    parameter POLY = 8'hD5; // x^8 + x^7 + x^6 + x^4 + x^2 + 1
    
    // State for handshake logic
    reg valid_prev;
    reg handshake_done;
    
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            crc_out <= 8'h00;
            ready <= 1'b0;
            valid_prev <= 1'b0;
            handshake_done <= 1'b0;
        end else begin
            // Edge detection for valid signal
            valid_prev <= valid;
            
            // Valid-Ready handshake process
            if (valid && !handshake_done) begin
                // New data is available and transaction not yet acknowledged
                crc_out <= {crc_out[6:0], 1'b0} ^ 
                          ({8{crc_out[7]}} & POLY) ^ data_in;
                ready <= 1'b1;
                handshake_done <= 1'b1;
            end else if (!valid && valid_prev) begin
                // Valid is deasserted, complete handshake
                ready <= 1'b0;
                handshake_done <= 1'b0;
            end
        end
    end
endmodule
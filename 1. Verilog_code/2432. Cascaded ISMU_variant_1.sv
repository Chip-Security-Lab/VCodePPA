//SystemVerilog
module cascaded_ismu(
    input wire clk,
    input wire reset,
    input wire [1:0] cascade_in,
    input wire [7:0] local_int,
    input wire [7:0] local_mask,
    input wire ack,           // Renamed from 'ready' to 'ack'
    output reg req,           // Renamed from 'valid' to 'req'
    output reg [3:0] int_id
);
    // IEEE 1364-2005 Verilog standard
    
    reg [7:0] masked_int;
    reg [3:0] local_id;
    reg local_valid;
    reg data_transferred;     // Flag to track successful data transfer
    
    always @(*) begin
        masked_int = local_int & ~local_mask;
        local_valid = |masked_int;
        local_id = masked_int[0] ? 4'd0 :
                  masked_int[1] ? 4'd1 :
                  masked_int[2] ? 4'd2 :
                  masked_int[3] ? 4'd3 :
                  masked_int[4] ? 4'd4 :
                  masked_int[5] ? 4'd5 :
                  masked_int[6] ? 4'd6 :
                  masked_int[7] ? 4'd7 : 4'd0;
    end
    
    always @(posedge clk or posedge reset) begin
        if (reset) begin
            int_id <= 4'd0;
            req <= 1'b0;
            data_transferred <= 1'b0;
        end else begin
            // Request-Acknowledge handshake logic
            if (req && ack) begin
                // Handshake complete, data transferred
                data_transferred <= 1'b1;
                req <= 1'b0; // Deassert request after transfer
            end else if (!req) begin
                // Prepare for next transfer
                if (local_valid || |cascade_in) begin
                    req <= 1'b1; // Assert request when new data is available
                    data_transferred <= 1'b0;
                    
                    // Update int_id based on priority
                    if (local_valid)
                        int_id <= local_id;
                    else if (cascade_in[0])
                        int_id <= 4'd8;
                    else if (cascade_in[1])
                        int_id <= 4'd9;
                end
            end
        end
    end
endmodule
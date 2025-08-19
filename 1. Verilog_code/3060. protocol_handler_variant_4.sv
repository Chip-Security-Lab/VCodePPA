//SystemVerilog
module protocol_handler(
    input wire clock, reset_n,
    input wire rx_data, rx_valid,
    output reg tx_data, tx_valid, error
);
    localparam IDLE=0, HEADER=1, PAYLOAD=2, CHECKSUM=3;
    reg [1:0] state, next;
    reg [3:0] byte_count;
    reg [7:0] checksum;
    reg [7:0] checksum_pipe;
    reg rx_data_pipe;
    reg rx_valid_pipe;
    reg [3:0] byte_count_pipe;
    
    // Pipeline stage 1
    always @(posedge clock or negedge reset_n)
        if (!reset_n) begin
            state <= IDLE;
            byte_count <= 4'd0;
            checksum <= 8'd0;
            checksum_pipe <= 8'd0;
            rx_data_pipe <= 1'b0;
            rx_valid_pipe <= 1'b0;
            byte_count_pipe <= 4'd0;
        end else begin
            state <= next;
            rx_data_pipe <= rx_data;
            rx_valid_pipe <= rx_valid;
            byte_count_pipe <= byte_count;
            
            if (rx_valid) begin
                if (state == PAYLOAD) begin
                    byte_count <= byte_count + 4'd1;
                    checksum_pipe <= karatsuba_mult(checksum, {7'd0, rx_data});
                end else if (state == HEADER) begin
                    byte_count <= 4'd0;
                    checksum_pipe <= 8'd0;
                end
            end
        end
    
    // Pipeline stage 2
    always @(posedge clock or negedge reset_n)
        if (!reset_n) begin
            checksum <= 8'd0;
        end else begin
            checksum <= checksum_pipe;
        end
    
    always @(*) begin
        next = state;
        tx_data = rx_data_pipe;
        tx_valid = 1'b0;
        error = 1'b0;
        
        case (state)
            IDLE: if (rx_valid_pipe && rx_data_pipe) next = HEADER;
            HEADER: if (rx_valid_pipe) next = PAYLOAD;
            PAYLOAD: begin
                tx_valid = rx_valid_pipe;
                if (rx_valid_pipe && byte_count_pipe == 4'd14) next = CHECKSUM;
            end
            CHECKSUM: begin
                if (rx_valid_pipe) begin
                    error = (checksum != {7'd0, rx_data_pipe});
                    next = IDLE;
                end
            end
        endcase
    end
    
    // Karatsuba multiplier function for 8-bit operands
    function [7:0] karatsuba_mult;
        input [7:0] a, b;
        reg [3:0] a_high, a_low, b_high, b_low;
        reg [7:0] z0, z1, z2;
        reg [7:0] result;
        begin
            // Split operands into high and low halves
            a_high = a[7:4];
            a_low = a[3:0];
            b_high = b[7:4];
            b_low = b[3:0];
            
            // Calculate partial products
            z0 = a_low * b_low;
            z2 = a_high * b_high;
            z1 = (a_high + a_low) * (b_high + b_low) - z0 - z2;
            
            // Combine results
            result = (z2 << 8) + (z1 << 4) + z0;
            karatsuba_mult = result[7:0]; // Return only 8 bits
        end
    endfunction
endmodule
//SystemVerilog
module eth_packet_filter #(parameter NUM_FILTERS = 4) (
    input wire clk,
    input wire rst_n,
    input wire [7:0] data_in,
    input wire data_valid,
    input wire packet_start,
    input wire packet_end,
    input wire [15:0] ethertype_filters [NUM_FILTERS-1:0],
    output reg packet_accept,
    output reg [NUM_FILTERS-1:0] filter_match
);
    // Split ethertype to separate upper and lower bytes
    reg [7:0] ethertype_upper;
    reg [7:0] ethertype_lower;
    reg [2:0] byte_count;
    reg recording_ethertype;
    reg packet_end_q;
    reg packet_start_q;
    reg data_valid_q;
    reg [7:0] data_in_q;
    
    // Register inputs to reduce input-to-register delay
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            data_valid_q <= 1'b0;
            data_in_q <= 8'd0;
            packet_start_q <= 1'b0;
            packet_end_q <= 1'b0;
        end else begin
            data_valid_q <= data_valid;
            data_in_q <= data_in;
            packet_start_q <= packet_start;
            packet_end_q <= packet_end;
        end
    end
    
    // Byte counter and ethertype extraction
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            byte_count <= 3'd0;
            recording_ethertype <= 1'b0;
            ethertype_upper <= 8'd0;
            ethertype_lower <= 8'd0;
        end else begin
            if (packet_start_q) begin
                byte_count <= 3'd0;
                recording_ethertype <= 1'b0;
            end else if (data_valid_q) begin
                if (byte_count < 12) begin
                    // Using Brent-Kung adder for byte count increment
                    byte_count <= brent_kung_adder_3bit(byte_count, 3'b001);
                    if (byte_count == 11)
                        recording_ethertype <= 1'b1;
                end else if (recording_ethertype) begin
                    if (byte_count == 12) begin
                        ethertype_upper <= data_in_q;
                        // Using Brent-Kung adder for byte count increment
                        byte_count <= brent_kung_adder_3bit(byte_count, 3'b001);
                    end else begin
                        ethertype_lower <= data_in_q;
                        recording_ethertype <= 1'b0;
                    end
                end
            end
        end
    end
    
    // Separate filter matching from ethertype capture to improve timing
    reg processing_match;
    reg [15:0] match_ethertype;
    
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            processing_match <= 1'b0;
            match_ethertype <= 16'd0;
        end else begin
            processing_match <= (recording_ethertype && byte_count == 13 && data_valid_q);
            if (recording_ethertype && byte_count == 13 && data_valid_q) begin
                match_ethertype <= {ethertype_upper, data_in_q};
            end
        end
    end
    
    // Separate output generation logic to balance pipeline stages
    integer i;
    
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            packet_accept <= 1'b0;
            filter_match <= {NUM_FILTERS{1'b0}};
        end else begin
            if (packet_start_q) begin
                filter_match <= {NUM_FILTERS{1'b0}};
                packet_accept <= 1'b0;
            end else if (processing_match) begin
                // Process all filters in parallel
                for (i = 0; i < NUM_FILTERS; i = i + 1) begin
                    if (brent_kung_comparator_16bit(match_ethertype, ethertype_filters[i])) begin
                        filter_match[i] <= 1'b1;
                        packet_accept <= 1'b1;
                    end
                end
            end
            
            if (packet_end_q) begin
                packet_accept <= 1'b0;
                filter_match <= {NUM_FILTERS{1'b0}};
            end
        end
    end
    
    // Brent-Kung Adder Implementation for 3-bit addition
    function [2:0] brent_kung_adder_3bit;
        input [2:0] a;
        input [2:0] b;
        reg [2:0] sum;
        reg [3:0] p, g; // Propagate and generate signals
        reg [3:0] pp, gg; // Intermediate propagate and generate
        
        begin
            // Step 1: Initial propagate and generate
            p[0] = a[0] ^ b[0];
            g[0] = a[0] & b[0];
            
            p[1] = a[1] ^ b[1];
            g[1] = a[1] & b[1];
            
            p[2] = a[2] ^ b[2];
            g[2] = a[2] & b[2];
            
            // Step 2: Tree computation for carry generation
            // First level
            pp[1] = p[1] & p[0];
            gg[1] = g[1] | (p[1] & g[0]);
            
            // Second level
            gg[2] = g[2] | (p[2] & gg[1]);
            
            // Step 3: Final sum computation
            sum[0] = p[0];
            sum[1] = p[1] ^ g[0];
            sum[2] = p[2] ^ gg[1];
            
            brent_kung_adder_3bit = sum;
        end
    endfunction
    
    // Brent-Kung 16-bit Equality Comparator
    function brent_kung_comparator_16bit;
        input [15:0] a;
        input [15:0] b;
        reg [15:0] xnor_result;
        reg [7:0] level1;
        reg [3:0] level2;
        reg [1:0] level3;
        begin
            // Step 1: Bitwise XNOR to check bit equality
            xnor_result = ~(a ^ b);
            
            // Step 2: Tree reduction (logarithmic comparison)
            // Level 1: 8 groups of 2 bits
            level1[0] = xnor_result[0] & xnor_result[1];
            level1[1] = xnor_result[2] & xnor_result[3];
            level1[2] = xnor_result[4] & xnor_result[5];
            level1[3] = xnor_result[6] & xnor_result[7];
            level1[4] = xnor_result[8] & xnor_result[9];
            level1[5] = xnor_result[10] & xnor_result[11];
            level1[6] = xnor_result[12] & xnor_result[13];
            level1[7] = xnor_result[14] & xnor_result[15];
            
            // Level 2: 4 groups of 2 groups
            level2[0] = level1[0] & level1[1];
            level2[1] = level1[2] & level1[3];
            level2[2] = level1[4] & level1[5];
            level2[3] = level1[6] & level1[7];
            
            // Level 3: 2 groups of 2 groups
            level3[0] = level2[0] & level2[1];
            level3[1] = level2[2] & level2[3];
            
            // Final result: AND of all levels
            brent_kung_comparator_16bit = level3[0] & level3[1];
        end
    endfunction
    
endmodule
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
    // Stage 1: Input Registration
    reg [7:0] data_in_s1;
    reg data_valid_s1;
    reg packet_start_s1;
    reg packet_end_s1;
    
    // Stage 2: Byte Counting and Ethertype Recording
    reg [2:0] byte_count_s2;
    reg recording_ethertype_s2;
    reg [15:8] ethertype_high_s2;
    reg [7:0] data_in_s2;
    reg data_valid_s2;
    reg packet_start_s2;
    reg packet_end_s2;
    
    // Stage 3: Ethertype Construction and Comparison
    reg [15:0] current_ethertype_s3;
    reg eth_type_valid_s3;
    reg data_valid_s3;
    reg packet_start_s3;
    reg packet_end_s3;
    
    // Stage 4: Match Detection and Output Generation
    reg [NUM_FILTERS-1:0] match_signals_s4;
    
    // Pipeline valid signals
    reg stage2_valid, stage3_valid, stage4_valid;
    
    // Generate match signals
    wire [NUM_FILTERS-1:0] match_signals;
    genvar j;
    generate
        for (j = 0; j < NUM_FILTERS; j = j + 1) begin : match_gen
            assign match_signals[j] = eth_type_valid_s3 && (current_ethertype_s3 == ethertype_filters[j]);
        end
    endgenerate
    
    // Stage 1: Input Registration
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            data_in_s1 <= 8'd0;
            data_valid_s1 <= 1'b0;
            packet_start_s1 <= 1'b0;
            packet_end_s1 <= 1'b0;
        end else begin
            data_in_s1 <= data_in;
            data_valid_s1 <= data_valid;
            packet_start_s1 <= packet_start;
            packet_end_s1 <= packet_end;
        end
    end
    
    // Stage 2: Byte Counting and Ethertype Recording
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            byte_count_s2 <= 3'd0;
            recording_ethertype_s2 <= 1'b0;
            ethertype_high_s2 <= 8'd0;
            data_in_s2 <= 8'd0;
            data_valid_s2 <= 1'b0;
            packet_start_s2 <= 1'b0;
            packet_end_s2 <= 1'b0;
            stage2_valid <= 1'b0;
        end else begin
            // Pass through control signals
            data_in_s2 <= data_in_s1;
            data_valid_s2 <= data_valid_s1;
            packet_start_s2 <= packet_start_s1;
            packet_end_s2 <= packet_end_s1;
            stage2_valid <= data_valid_s1;
            
            if (packet_start_s1) begin
                byte_count_s2 <= 3'd0;
                recording_ethertype_s2 <= 1'b0;
            end else if (data_valid_s1) begin
                // Byte count logic
                if (byte_count_s2 < 3'd7 || (byte_count_s2 >= 3'd7 && byte_count_s2 < 3'd13)) begin
                    byte_count_s2 <= byte_count_s2 + 3'd1;
                end
                
                // Ethertype recording stage transition
                if (byte_count_s2 == 3'd11) begin
                    recording_ethertype_s2 <= 1'b1;
                end else if (recording_ethertype_s2 && byte_count_s2 == 3'd13) begin
                    recording_ethertype_s2 <= 1'b0;
                end
                
                // Store high byte of ethertype
                if (recording_ethertype_s2 && byte_count_s2 == 3'd12) begin
                    ethertype_high_s2 <= data_in_s1;
                end
            end
        end
    end
    
    // Stage 3: Ethertype Construction and Comparison
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            current_ethertype_s3 <= 16'd0;
            eth_type_valid_s3 <= 1'b0;
            data_valid_s3 <= 1'b0;
            packet_start_s3 <= 1'b0;
            packet_end_s3 <= 1'b0;
            stage3_valid <= 1'b0;
        end else begin
            // Pass through control signals
            data_valid_s3 <= data_valid_s2;
            packet_start_s3 <= packet_start_s2;
            packet_end_s3 <= packet_end_s2;
            stage3_valid <= stage2_valid;
            
            // Construct full ethertype and validate it
            if (recording_ethertype_s2 && byte_count_s2 == 3'd13) begin
                current_ethertype_s3 <= {ethertype_high_s2, data_in_s2};
                eth_type_valid_s3 <= 1'b1;
            end else begin
                eth_type_valid_s3 <= 1'b0;
            end
        end
    end
    
    // Stage 4: Match Detection and Output Generation
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            match_signals_s4 <= {NUM_FILTERS{1'b0}};
            packet_accept <= 1'b0;
            filter_match <= {NUM_FILTERS{1'b0}};
            stage4_valid <= 1'b0;
        end else begin
            // Register match signals to break combinational path
            match_signals_s4 <= match_signals;
            stage4_valid <= stage3_valid;
            
            if (packet_start_s3) begin
                filter_match <= {NUM_FILTERS{1'b0}};
                packet_accept <= 1'b0;
            end else if (eth_type_valid_s3) begin
                filter_match <= match_signals_s4;
                packet_accept <= |match_signals_s4;
            end
            
            if (packet_end_s3) begin
                packet_accept <= 1'b0;
                filter_match <= {NUM_FILTERS{1'b0}};
            end
        end
    end
endmodule
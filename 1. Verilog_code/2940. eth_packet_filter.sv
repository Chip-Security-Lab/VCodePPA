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
    reg [15:0] current_ethertype;
    reg [2:0] byte_count;
    reg recording_ethertype;
    
    integer i;
    
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            packet_accept <= 1'b0;
            filter_match <= {NUM_FILTERS{1'b0}};
            byte_count <= 3'd0;
            recording_ethertype <= 1'b0;
            current_ethertype <= 16'd0;
        end else begin
            if (packet_start) begin
                byte_count <= 3'd0;
                recording_ethertype <= 1'b0;
                filter_match <= {NUM_FILTERS{1'b0}};
                packet_accept <= 1'b0;
            end else if (data_valid) begin
                if (byte_count < 12) begin
                    // Counting through destination and source MAC
                    byte_count <= byte_count + 1'b1;
                    if (byte_count == 11)
                        recording_ethertype <= 1'b1;
                end else if (recording_ethertype) begin
                    if (byte_count == 12) begin
                        current_ethertype[15:8] <= data_in;
                        byte_count <= byte_count + 1'b1;
                    end else begin
                        current_ethertype[7:0] <= data_in;
                        recording_ethertype <= 1'b0;
                        
                        // Check for matches with filters
                        for (i = 0; i < NUM_FILTERS; i = i + 1) begin
                            if ({current_ethertype[15:8], data_in} == ethertype_filters[i]) begin
                                filter_match[i] <= 1'b1;
                                packet_accept <= 1'b1;
                            end
                        end
                    end
                end
            end
            
            if (packet_end) begin
                packet_accept <= 1'b0;
                filter_match <= {NUM_FILTERS{1'b0}};
            end
        end
    end
endmodule
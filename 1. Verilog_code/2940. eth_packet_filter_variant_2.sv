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
    // State encoding with one-hot for better timing
    localparam STATE_HEADER = 3'b001;
    localparam STATE_ETH_HIGH = 3'b010;
    localparam STATE_ETH_LOW = 3'b100;
    
    // Stage 1: Input capture and state tracking
    reg [2:0] state_stage1;
    reg [3:0] byte_counter_stage1;
    reg [7:0] data_stage1;
    reg data_valid_stage1;
    reg packet_end_stage1;
    
    // Stage 2: Ethertype assembly
    reg [7:0] data_stage2, ethertype_high_stage2;
    reg data_valid_stage2;
    reg packet_end_stage2;
    reg ethertype_ready_stage2;
    reg [15:0] current_ethertype_stage2;
    
    // Stage 3: Filter matching using optimized comparison
    reg [15:0] current_ethertype_stage3;
    reg data_valid_stage3;
    reg packet_end_stage3;
    reg ethertype_valid_stage3;
    reg [NUM_FILTERS-1:0] filter_match_stage3;
    reg packet_accept_stage3;
    
    // Look-up table for filter matching
    reg [NUM_FILTERS-1:0] match_results;
    
    // Stage 1: Optimized state machine for header processing
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            state_stage1 <= STATE_HEADER;
            byte_counter_stage1 <= 4'd0;
            data_stage1 <= 8'd0;
            data_valid_stage1 <= 1'b0;
            packet_end_stage1 <= 1'b0;
        end else begin
            // Register inputs
            data_stage1 <= data_in;
            data_valid_stage1 <= data_valid;
            packet_end_stage1 <= packet_end;
            
            // Reset on packet start
            if (packet_start) begin
                state_stage1 <= STATE_HEADER;
                byte_counter_stage1 <= 4'd0;
            end else if (data_valid) begin
                case (state_stage1)
                    STATE_HEADER: begin
                        // Count through MAC addresses (12 bytes total)
                        if (byte_counter_stage1 < 4'd11) begin
                            byte_counter_stage1 <= byte_counter_stage1 + 4'd1;
                        end else begin
                            state_stage1 <= STATE_ETH_HIGH;
                            byte_counter_stage1 <= 4'd0;
                        end
                    end
                    
                    STATE_ETH_HIGH: begin
                        state_stage1 <= STATE_ETH_LOW;
                    end
                    
                    STATE_ETH_LOW: begin
                        state_stage1 <= STATE_HEADER;
                    end
                    
                    default: state_stage1 <= STATE_HEADER;
                endcase
            end
        end
    end
    
    // Stage 2: Optimized ethertype assembly
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            data_stage2 <= 8'd0;
            ethertype_high_stage2 <= 8'd0;
            data_valid_stage2 <= 1'b0;
            packet_end_stage2 <= 1'b0;
            ethertype_ready_stage2 <= 1'b0;
            current_ethertype_stage2 <= 16'd0;
        end else begin
            // Forward signals to next stage
            data_stage2 <= data_stage1;
            data_valid_stage2 <= data_valid_stage1;
            packet_end_stage2 <= packet_end_stage1;
            
            if (packet_start) begin
                ethertype_ready_stage2 <= 1'b0;
                current_ethertype_stage2 <= 16'd0;
            end else if (data_valid_stage1) begin
                case (state_stage1)
                    STATE_ETH_HIGH: begin
                        ethertype_high_stage2 <= data_stage1;
                        ethertype_ready_stage2 <= 1'b0;
                    end
                    
                    STATE_ETH_LOW: begin
                        current_ethertype_stage2 <= {ethertype_high_stage2, data_stage1};
                        ethertype_ready_stage2 <= 1'b1;
                    end
                    
                    default: ethertype_ready_stage2 <= 1'b0;
                endcase
            end else begin
                ethertype_ready_stage2 <= 1'b0;
            end
        end
    end
    
    // Optimized parallel comparison logic
    genvar j;
    generate
        for (j = 0; j < NUM_FILTERS; j = j + 1) begin : filter_compare
            always @(*) begin
                match_results[j] = (current_ethertype_stage2 == ethertype_filters[j]);
            end
        end
    endgenerate
    
    // Stage 3: Filter matching with optimized comparison
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            current_ethertype_stage3 <= 16'd0;
            data_valid_stage3 <= 1'b0;
            packet_end_stage3 <= 1'b0;
            ethertype_valid_stage3 <= 1'b0;
            filter_match_stage3 <= {NUM_FILTERS{1'b0}};
            packet_accept_stage3 <= 1'b0;
        end else begin
            // Forward signals to next stage
            current_ethertype_stage3 <= current_ethertype_stage2;
            data_valid_stage3 <= data_valid_stage2;
            packet_end_stage3 <= packet_end_stage2;
            ethertype_valid_stage3 <= ethertype_ready_stage2;
            
            if (packet_start) begin
                filter_match_stage3 <= {NUM_FILTERS{1'b0}};
                packet_accept_stage3 <= 1'b0;
            end else if (data_valid_stage2 && ethertype_ready_stage2) begin
                // Use pre-computed match results
                filter_match_stage3 <= match_results;
                // Accept if any filter matches
                packet_accept_stage3 <= |match_results;
            end
            
            if (packet_end_stage2) begin
                filter_match_stage3 <= {NUM_FILTERS{1'b0}};
                packet_accept_stage3 <= 1'b0;
            end
        end
    end
    
    // Output stage with synchronized reset on packet end
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            packet_accept <= 1'b0;
            filter_match <= {NUM_FILTERS{1'b0}};
        end else begin
            packet_accept <= packet_accept_stage3;
            filter_match <= filter_match_stage3;
            
            if (packet_end_stage3) begin
                packet_accept <= 1'b0;
                filter_match <= {NUM_FILTERS{1'b0}};
            end
        end
    end
endmodule
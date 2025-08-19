//SystemVerilog
module eth_packet_generator (
    input wire clk,
    input wire reset,
    input wire enable,
    input wire [47:0] src_mac,
    input wire [47:0] dst_mac,
    input wire [15:0] ethertype,
    input wire [7:0] payload_pattern,
    input wire [10:0] payload_length,
    
    // AXI-Stream interface
    output reg [7:0] m_axis_tdata,
    output reg m_axis_tvalid,
    input wire m_axis_tready,
    output reg m_axis_tlast,
    
    output reg tx_done
);
    // States definition
    localparam IDLE = 3'd0, PREAMBLE = 3'd1, DST_MAC = 3'd2;
    localparam SRC_MAC = 3'd3, ETHERTYPE = 3'd4, PAYLOAD = 3'd5, FCS = 3'd6;
    
    // Pipeline stage registers
    reg [2:0] state_stage1, state_stage2;
    reg [10:0] byte_count_stage1, byte_count_stage2;
    reg [7:0] data_to_send_stage1, data_to_send_stage2;
    reg data_valid_stage1, data_valid_stage2;
    reg packet_done_stage1, packet_done_stage2;
    reg m_axis_tlast_stage1, m_axis_tlast_stage2;
    
    // Registered input signals for better timing
    reg enable_reg;
    reg [47:0] src_mac_reg, dst_mac_reg;
    reg [15:0] ethertype_reg;
    reg [7:0] payload_pattern_reg;
    reg [10:0] payload_length_reg;
    reg m_axis_tready_reg;
    
    // First pipeline stage: State determination and data preparation
    always @(posedge clk or posedge reset) begin
        if (reset) begin
            state_stage1 <= IDLE;
            byte_count_stage1 <= 11'd0;
            data_valid_stage1 <= 1'b0;
            data_to_send_stage1 <= 8'd0;
            packet_done_stage1 <= 1'b0;
            m_axis_tlast_stage1 <= 1'b0;
            
            // Register input signals
            enable_reg <= 1'b0;
            src_mac_reg <= 48'd0;
            dst_mac_reg <= 48'd0;
            ethertype_reg <= 16'd0;
            payload_pattern_reg <= 8'd0;
            payload_length_reg <= 11'd0;
            m_axis_tready_reg <= 1'b0;
        end else begin
            // Register input signals for better timing
            enable_reg <= enable;
            src_mac_reg <= src_mac;
            dst_mac_reg <= dst_mac;
            ethertype_reg <= ethertype;
            payload_pattern_reg <= payload_pattern;
            payload_length_reg <= payload_length;
            m_axis_tready_reg <= m_axis_tready;
            
            // Default assignments
            data_valid_stage1 <= 1'b0;
            data_to_send_stage1 <= 8'd0;
            packet_done_stage1 <= 1'b0;
            m_axis_tlast_stage1 <= 1'b0;
            
            case (state_stage1)
                IDLE: begin
                    if (enable_reg) begin
                        state_stage1 <= PREAMBLE;
                        byte_count_stage1 <= 11'd0;
                        data_valid_stage1 <= 1'b1;
                        data_to_send_stage1 <= 8'h55; // First byte of preamble
                    end
                end
                
                PREAMBLE: begin
                    data_valid_stage1 <= 1'b1;
                    data_to_send_stage1 <= (byte_count_stage1 < 7) ? 8'h55 : 8'hD5;
                    
                    if (m_axis_tready_reg) begin
                        if (byte_count_stage1 == 7) begin
                            state_stage1 <= DST_MAC;
                            byte_count_stage1 <= 11'd0;
                        end else begin
                            byte_count_stage1 <= byte_count_stage1 + 1'b1;
                        end
                    end
                end
                
                DST_MAC: begin
                    data_valid_stage1 <= 1'b1;
                    data_to_send_stage1 <= dst_mac_reg[47-8*byte_count_stage1 -: 8];
                    
                    if (m_axis_tready_reg) begin
                        if (byte_count_stage1 == 5) begin
                            state_stage1 <= SRC_MAC;
                            byte_count_stage1 <= 11'd0;
                        end else begin
                            byte_count_stage1 <= byte_count_stage1 + 1'b1;
                        end
                    end
                end
                
                SRC_MAC: begin
                    data_valid_stage1 <= 1'b1;
                    data_to_send_stage1 <= src_mac_reg[47-8*byte_count_stage1 -: 8];
                    
                    if (m_axis_tready_reg) begin
                        if (byte_count_stage1 == 5) begin
                            state_stage1 <= ETHERTYPE;
                            byte_count_stage1 <= 11'd0;
                        end else begin
                            byte_count_stage1 <= byte_count_stage1 + 1'b1;
                        end
                    end
                end
                
                ETHERTYPE: begin
                    data_valid_stage1 <= 1'b1;
                    data_to_send_stage1 <= (byte_count_stage1 == 0) ? ethertype_reg[15:8] : ethertype_reg[7:0];
                    
                    if (m_axis_tready_reg) begin
                        if (byte_count_stage1 == 1) begin
                            state_stage1 <= PAYLOAD;
                            byte_count_stage1 <= 11'd0;
                        end else begin
                            byte_count_stage1 <= byte_count_stage1 + 1'b1;
                        end
                    end
                end
                
                PAYLOAD: begin
                    data_valid_stage1 <= 1'b1;
                    data_to_send_stage1 <= payload_pattern_reg + byte_count_stage1[7:0];
                    
                    if (m_axis_tready_reg) begin
                        if (byte_count_stage1 == payload_length_reg - 1) begin
                            state_stage1 <= FCS;
                            byte_count_stage1 <= 11'd0;
                        end else begin
                            byte_count_stage1 <= byte_count_stage1 + 1'b1;
                        end
                    end
                end
                
                FCS: begin
                    data_valid_stage1 <= 1'b1;
                    data_to_send_stage1 <= 8'hAA; // Simple placeholder for CRC
                    
                    // Set TLAST on the last byte of FCS
                    if (byte_count_stage1 == 3)
                        m_axis_tlast_stage1 <= 1'b1;
                    
                    if (m_axis_tready_reg) begin
                        if (byte_count_stage1 == 3) begin
                            state_stage1 <= IDLE;
                            byte_count_stage1 <= 11'd0;
                            packet_done_stage1 <= 1'b1;
                        end else begin
                            byte_count_stage1 <= byte_count_stage1 + 1'b1;
                        end
                    end
                end
            endcase
        end
    end
    
    // Second pipeline stage: Output control signals
    always @(posedge clk or posedge reset) begin
        if (reset) begin
            state_stage2 <= IDLE;
            byte_count_stage2 <= 11'd0;
            data_valid_stage2 <= 1'b0;
            data_to_send_stage2 <= 8'd0;
            packet_done_stage2 <= 1'b0;
            m_axis_tlast_stage2 <= 1'b0;
            
            // Output registers
            m_axis_tvalid <= 1'b0;
            m_axis_tdata <= 8'd0;
            m_axis_tlast <= 1'b0;
            tx_done <= 1'b0;
        end else begin
            // Propagate pipeline stage 1 to stage 2 registers
            state_stage2 <= state_stage1;
            byte_count_stage2 <= byte_count_stage1;
            data_valid_stage2 <= data_valid_stage1;
            data_to_send_stage2 <= data_to_send_stage1;
            packet_done_stage2 <= packet_done_stage1;
            m_axis_tlast_stage2 <= m_axis_tlast_stage1;
            
            // Final output stage
            if (m_axis_tready || state_stage2 == IDLE) begin
                m_axis_tvalid <= data_valid_stage2;
                if (data_valid_stage2) m_axis_tdata <= data_to_send_stage2;
                m_axis_tlast <= m_axis_tlast_stage2;
                tx_done <= packet_done_stage2;
            end
        end
    end
endmodule
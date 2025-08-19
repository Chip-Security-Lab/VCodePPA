//SystemVerilog
module packet_buf #(parameter DW=8) (
    input clk, rst_n,
    input [DW-1:0] din,
    input din_valid,
    output reg [DW-1:0] dout,
    output reg pkt_valid
);
    // Pipeline stage registers
    reg [DW-1:0] din_stage1;
    reg din_valid_stage1;
    reg [DW-1:0] din_stage2;
    reg din_valid_stage2;
    
    // Pipeline control signals
    reg detect_delimiter_stage1;
    reg packet_start_stage2;
    
    // Delimiter constant
    localparam [7:0] DELIMITER = 8'hFF;
    
    // Pre-compute delimiter detection in parallel
    wire is_delimiter = (din == DELIMITER);
    
    // Stage 0: Input capture with parallel processing paths
    always @(posedge clk or negedge rst_n) begin
        if(!rst_n) begin
            din_stage1 <= {DW{1'b0}};
            din_valid_stage1 <= 1'b0;
            detect_delimiter_stage1 <= 1'b0;
        end
        else begin
            din_stage1 <= din;
            din_valid_stage1 <= din_valid;
            detect_delimiter_stage1 <= din_valid & is_delimiter; // Simplified logic
        end
    end
    
    // Stage 1: Packet identification with balanced paths
    always @(posedge clk or negedge rst_n) begin
        if(!rst_n) begin
            din_stage2 <= {DW{1'b0}};
            din_valid_stage2 <= 1'b0;
            packet_start_stage2 <= 1'b0;
        end
        else begin
            din_stage2 <= din_stage1;
            din_valid_stage2 <= din_valid_stage1;
            packet_start_stage2 <= detect_delimiter_stage1;
        end
    end
    
    // Pre-compute output stage control signals
    reg active_packet;
    wire update_active = din_valid_stage2 & (packet_start_stage2 | active_packet);
    
    // Stage 2: Output generation with balanced paths
    always @(posedge clk or negedge rst_n) begin
        if(!rst_n) begin
            dout <= {DW{1'b0}};
            pkt_valid <= 1'b0;
            active_packet <= 1'b0;
        end
        else begin
            // Update data output unconditionally to reduce mux depth
            dout <= din_stage2;
            
            // Simplified packet valid logic with reduced critical path
            pkt_valid <= din_valid_stage2 & (packet_start_stage2 | active_packet);
            
            // Balanced active packet control logic
            if(din_valid_stage2) begin
                active_packet <= packet_start_stage2 ? 1'b1 : active_packet;
            end
            else begin
                active_packet <= 1'b0;
            end
        end
    end
endmodule
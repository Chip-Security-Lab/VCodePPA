//SystemVerilog
module eth_broadcast_filter (
    input wire clk,
    input wire rst_n,
    input wire [7:0] data_in,
    input wire data_valid,
    input wire frame_start,
    output reg [7:0] data_out,
    output reg data_valid_out,
    output reg broadcast_detected,
    input wire pass_broadcast
);
    // Stage 1 - Input capturing and initial processing
    reg [7:0] data_stage1;
    reg data_valid_stage1;
    reg frame_start_stage1;
    reg [2:0] byte_counter_stage1;  // Optimized to 3 bits since we only count to 5
    reg broadcast_check_stage1;
    
    // Stage 2 - MAC address building
    reg [7:0] data_stage2;
    reg data_valid_stage2;
    reg [2:0] byte_counter_stage2;  // Optimized to 3 bits
    reg [47:0] dest_mac_stage2;
    reg broadcast_check_stage2;
    
    // Stage 3 - Broadcast detection and decision
    reg [7:0] data_stage3;
    reg data_valid_stage3;
    reg broadcast_frame_stage3;
    reg pass_broadcast_stage3;
    
    // Optimized comparison constant
    localparam BROADCAST_BYTE = 8'hFF;
    localparam MAC_ADDR_LENGTH = 3'd6;  // Using 3 bits for comparison efficiency
    
    // Stage 1: Input capturing and initial processing - optimized comparison logic
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            data_stage1 <= 8'd0;
            data_valid_stage1 <= 1'b0;
            frame_start_stage1 <= 1'b0;
            byte_counter_stage1 <= 3'd0;
            broadcast_check_stage1 <= 1'b1;
        end else begin
            data_stage1 <= data_in;
            data_valid_stage1 <= data_valid;
            frame_start_stage1 <= frame_start;
            
            if (frame_start) begin
                byte_counter_stage1 <= 3'd0;
                broadcast_check_stage1 <= 1'b1;
            end else if (data_valid) begin
                // Increment counter only when it's less than 5 (will be 6 after increment)
                if (byte_counter_stage1 < MAC_ADDR_LENGTH - 1'b1)
                    byte_counter_stage1 <= byte_counter_stage1 + 1'b1;
                
                // Single condition check for non-broadcast byte
                if (byte_counter_stage1 < MAC_ADDR_LENGTH - 1'b1 && data_in != BROADCAST_BYTE)
                    broadcast_check_stage1 <= 1'b0;
            end
        end
    end
    
    // Stage 2: MAC address building - optimized shifter
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            data_stage2 <= 8'd0;
            data_valid_stage2 <= 1'b0;
            byte_counter_stage2 <= 3'd0;
            dest_mac_stage2 <= 48'd0;
            broadcast_check_stage2 <= 1'b0;
        end else begin
            data_stage2 <= data_stage1;
            data_valid_stage2 <= data_valid_stage1;
            byte_counter_stage2 <= byte_counter_stage1;
            broadcast_check_stage2 <= broadcast_check_stage1;
            
            if (frame_start_stage1) begin
                dest_mac_stage2 <= 48'd0;
            end else if (data_valid_stage1 && byte_counter_stage1 < MAC_ADDR_LENGTH - 1'b1) begin
                // Optimized shifting using direct concatenation
                dest_mac_stage2 <= {dest_mac_stage2[39:0], data_stage1};
            end
        end
    end
    
    // Stage 3: Broadcast detection and decision - simplified logic
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            data_stage3 <= 8'd0;
            data_valid_stage3 <= 1'b0;
            broadcast_frame_stage3 <= 1'b0;
            pass_broadcast_stage3 <= 1'b0;
        end else begin
            data_stage3 <= data_stage2;
            data_valid_stage3 <= data_valid_stage2;
            pass_broadcast_stage3 <= pass_broadcast;
            
            if (frame_start_stage1) begin
                broadcast_frame_stage3 <= 1'b0;
            end else if (byte_counter_stage2 == MAC_ADDR_LENGTH - 1'b1 && data_valid_stage2 && broadcast_check_stage2) begin
                // Optimized broadcast detection condition
                broadcast_frame_stage3 <= 1'b1;
            end
        end
    end
    
    // Output stage: Final decision and data output - optimized conditional logic
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            data_out <= 8'd0;
            data_valid_out <= 1'b0;
            broadcast_detected <= 1'b0;
        end else begin
            data_out <= data_stage3;
            
            // Combined reset and detection in one condition
            broadcast_detected <= frame_start_stage1 ? 1'b0 : 
                                 (broadcast_frame_stage3 ? 1'b1 : broadcast_detected);
            
            // Optimized output enable logic
            data_valid_out <= data_valid_stage3 && (pass_broadcast_stage3 || !broadcast_frame_stage3);
        end
    end
endmodule
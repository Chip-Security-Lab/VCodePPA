//SystemVerilog
module eth_packet_counter #(parameter COUNTER_WIDTH = 32) (
    input wire clk,
    input wire reset_n,
    input wire packet_valid,
    input wire packet_error,
    output reg [COUNTER_WIDTH-1:0] good_packets,
    output reg [COUNTER_WIDTH-1:0] error_packets,
    output reg [COUNTER_WIDTH-1:0] total_packets
);
    // Pre-compute increment conditions to reduce critical path
    reg update_good_packets;
    reg update_error_packets;
    reg update_total_packets;
    
    // Separate condition evaluation from counter updates
    always @(*) begin
        update_total_packets = packet_valid;
        update_good_packets = packet_valid && !packet_error;
        update_error_packets = packet_valid && packet_error;
    end
    
    // Counter update logic with balanced paths
    always @(posedge clk or negedge reset_n) begin
        if (!reset_n) begin
            good_packets <= {COUNTER_WIDTH{1'b0}};
            error_packets <= {COUNTER_WIDTH{1'b0}};
            total_packets <= {COUNTER_WIDTH{1'b0}};
        end else begin
            // Use pre-computed conditions for balanced paths
            if (update_good_packets)
                good_packets <= good_packets + 1'b1;
                
            if (update_error_packets)
                error_packets <= error_packets + 1'b1;
                
            if (update_total_packets)
                total_packets <= total_packets + 1'b1;
        end
    end
endmodule
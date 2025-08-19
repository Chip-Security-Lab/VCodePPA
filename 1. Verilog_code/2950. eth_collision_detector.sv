module eth_collision_detector (
    input wire clk,
    input wire rst_n,
    input wire transmitting,
    input wire receiving,
    input wire carrier_sense,
    output reg collision_detected,
    output reg jam_active,
    output reg [3:0] backoff_count,
    output reg [15:0] backoff_time
);
    reg [3:0] collision_count;
    reg [7:0] jam_counter;
    
    localparam JAM_SIZE = 8'd32; // 32-byte jam pattern (16-bit time)
    
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            collision_detected <= 1'b0;
            jam_active <= 1'b0;
            backoff_count <= 4'd0;
            backoff_time <= 16'd0;
            collision_count <= 4'd0;
            jam_counter <= 8'd0;
        end else begin
            // Detect collision
            if (transmitting && (receiving || carrier_sense)) begin
                collision_detected <= 1'b1;
                jam_active <= 1'b1;
                jam_counter <= JAM_SIZE;
                
                if (!collision_detected) begin
                    collision_count <= collision_count + 1'b1;
                    
                    // Calculate backoff using truncated binary exponential algorithm
                    if (collision_count < 10) begin
                        // r = random number between 0 and 2^k - 1, where k = min(n, 10)
                        // Simplified random implementation for simulation
                        backoff_time <= (16'd1 << collision_count) - 1'b1;
                    end else begin
                        // Max backoff for >= 10 collisions
                        backoff_time <= 16'd1023; // 2^10 - 1
                    end
                    
                    backoff_count <= collision_count;
                end
            end else if (!transmitting) begin
                collision_detected <= 1'b0;
            end
            
            // Jam signal generation
            if (jam_active) begin
                if (jam_counter > 0)
                    jam_counter <= jam_counter - 1'b1;
                else
                    jam_active <= 1'b0;
            end
            
            // Reset collision count after successful transmission
            if (!transmitting && !receiving && !collision_detected && collision_count > 0) begin
                collision_count <= 4'd0;
            end
        end
    end
endmodule
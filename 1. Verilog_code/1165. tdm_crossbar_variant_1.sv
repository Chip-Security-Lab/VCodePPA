//SystemVerilog
module tdm_crossbar (
    input wire clock, reset,
    input wire [7:0] in0, in1, in2, in3,
    output reg [7:0] out0, out1, out2, out3
);
    // Time-division multiplexed crossbar using fixed schedule
    reg [1:0] time_slot;  // Current time slot
    wire [1:0] next_time_slot;
    
    // Multi-level buffered time_slot signals to reduce fan-out
    reg [1:0] time_slot_buf1, time_slot_buf2, time_slot_buf3, time_slot_buf4;
    
    // Multi-level buffered next_time_slot signals to reduce fan-out
    reg [1:0] next_time_slot_buf1, next_time_slot_buf2, next_time_slot_buf3;
    
    // Look-ahead carry adder for time_slot increment
    wire gen, prop, carry_out;
    
    // Generate and propagate signals for carry look-ahead
    assign gen = time_slot[0] & time_slot[1];
    assign prop = time_slot[0] | time_slot[1];
    
    // Carry look-ahead logic
    assign carry_out = gen | (prop & 1'b0); // Carry-in is 0
    
    // Calculate next time slot value using carry look-ahead adder
    assign next_time_slot[0] = time_slot[0] ^ 1'b1;  // LSB is always toggled
    assign next_time_slot[1] = time_slot[1] ^ (time_slot[0] & 1'b1); // MSB toggled when LSB is 1
    
    // Buffered input signals for group A (used with time_slot_buf1, time_slot_buf2)
    reg [7:0] in0_bufA1, in0_bufA2;
    reg [7:0] in1_bufA1, in1_bufA2;
    reg [7:0] in2_bufA1, in2_bufA2;
    reg [7:0] in3_bufA1, in3_bufA2;
    
    // Buffered input signals for group B (used with time_slot_buf3, time_slot_buf4)
    reg [7:0] in0_bufB1, in0_bufB2;
    reg [7:0] in1_bufB1, in1_bufB2;
    reg [7:0] in2_bufB1, in2_bufB2;
    reg [7:0] in3_bufB1, in3_bufB2;
    
    // Buffer for output reset value
    reg [7:0] h00_buf1, h00_buf2, h00_buf3, h00_buf4;
    
    // Buffer register implementation - first stage
    always @(posedge clock or posedge reset) begin
        if (reset) begin
            // Reset next_time_slot buffers
            next_time_slot_buf1 <= 2'b00;
            next_time_slot_buf2 <= 2'b00;
            
            // Reset h00 buffers
            h00_buf1 <= 8'h00;
            h00_buf2 <= 8'h00;
            
            // Reset group A buffers - first half
            in0_bufA1 <= 8'h00;
            in1_bufA1 <= 8'h00;
            in2_bufA1 <= 8'h00;
            in3_bufA1 <= 8'h00;
            
            // Reset group B buffers - first half
            in0_bufB1 <= 8'h00;
            in1_bufB1 <= 8'h00;
            in2_bufB1 <= 8'h00;
            in3_bufB1 <= 8'h00;
        end else begin
            // Buffer next_time_slot in multi-level structure
            next_time_slot_buf1 <= next_time_slot;
            next_time_slot_buf2 <= next_time_slot;
            
            // Buffer reset value with dedicated fan-out distribution
            h00_buf1 <= 8'h00;
            h00_buf2 <= 8'h00;
            
            // Buffer group A input signals - first half
            in0_bufA1 <= in0;
            in1_bufA1 <= in1;
            in2_bufA1 <= in2;
            in3_bufA1 <= in3;
            
            // Buffer group B input signals - first half
            in0_bufB1 <= in0;
            in1_bufB1 <= in1;
            in2_bufB1 <= in2;
            in3_bufB1 <= in3;
        end
    end
    
    // Buffer register implementation - second stage
    always @(posedge clock or posedge reset) begin
        if (reset) begin
            // Reset time_slot buffers
            time_slot_buf1 <= 2'b00;
            time_slot_buf2 <= 2'b00;
            
            // Reset next_time_slot buffer - second stage
            next_time_slot_buf3 <= 2'b00;
            
            // Reset h00 buffers - second stage
            h00_buf3 <= 8'h00;
            h00_buf4 <= 8'h00;
            
            // Reset group A buffers - second half
            in0_bufA2 <= 8'h00;
            in1_bufA2 <= 8'h00;
            in2_bufA2 <= 8'h00;
            in3_bufA2 <= 8'h00;
            
            // Reset group B buffers - second half
            in0_bufB2 <= 8'h00;
            in1_bufB2 <= 8'h00;
            in2_bufB2 <= 8'h00;
            in3_bufB2 <= 8'h00;
        end else begin
            // Buffer time_slot for first half of routing logic
            time_slot_buf1 <= time_slot;
            time_slot_buf2 <= time_slot;
            
            // Additional stage for next_time_slot buffer
            next_time_slot_buf3 <= next_time_slot_buf1;
            
            // Buffer reset value with dedicated fan-out distribution - second stage
            h00_buf3 <= h00_buf1;
            h00_buf4 <= h00_buf2;
            
            // Buffer group A input signals - second half
            in0_bufA2 <= in0_bufA1;
            in1_bufA2 <= in1_bufA1;
            in2_bufA2 <= in2_bufA1;
            in3_bufA2 <= in3_bufA1;
            
            // Buffer group B input signals - second half
            in0_bufB2 <= in0_bufB1;
            in1_bufB2 <= in1_bufB1;
            in2_bufB2 <= in2_bufB1;
            in3_bufB2 <= in3_bufB1;
        end
    end
    
    // Buffer register implementation - third stage for time_slot
    always @(posedge clock or posedge reset) begin
        if (reset) begin
            // Reset time_slot buffers - second half
            time_slot_buf3 <= 2'b00;
            time_slot_buf4 <= 2'b00;
        end else begin
            // Buffer time_slot for second half of routing logic
            time_slot_buf3 <= time_slot;
            time_slot_buf4 <= time_slot;
        end
    end
    
    // Main state update and crossbar routing logic
    always @(posedge clock or posedge reset) begin
        if (reset) begin
            time_slot <= 2'b00;
            out0 <= h00_buf3; // Use buffered reset value
            out1 <= h00_buf3;
            out2 <= h00_buf4;
            out3 <= h00_buf4;
        end else begin
            // Rotate time slot on each clock using buffered look-ahead adder result
            time_slot <= next_time_slot_buf3;
            
            // Use balanced buffered signals for crossbar routing
            case (time_slot_buf1) // Use first buffer for first two cases
                2'b00: begin
                    out0 <= in0_bufA1; 
                    out1 <= in1_bufA1; 
                    out2 <= in2_bufA1; 
                    out3 <= in3_bufA1;
                end
                2'b01: begin
                    out0 <= in3_bufA2; 
                    out1 <= in0_bufA2; 
                    out2 <= in1_bufA2; 
                    out3 <= in2_bufA2;
                end
                default: begin
                    // This will be overridden by the next case statement
                    // but needed to avoid latches
                    out0 <= h00_buf3;
                    out1 <= h00_buf3;
                    out2 <= h00_buf4;
                    out3 <= h00_buf4;
                end
            endcase
            
            // Use second buffer pair for last two cases
            case (time_slot_buf3) 
                2'b10: begin
                    out0 <= in2_bufB1; 
                    out1 <= in3_bufB1; 
                    out2 <= in0_bufB1; 
                    out3 <= in1_bufB1;
                end
                2'b11: begin
                    out0 <= in1_bufB2; 
                    out1 <= in2_bufB2; 
                    out2 <= in3_bufB2; 
                    out3 <= in0_bufB2;
                end
                default: begin
                    // No action needed here - values will only be used when time_slot matches
                end
            endcase
        end
    end
endmodule
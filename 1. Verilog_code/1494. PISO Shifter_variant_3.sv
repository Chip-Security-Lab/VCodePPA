//SystemVerilog
module piso_shifter (
    input wire clk, clear,
    input wire req,              // Request signal
    input wire [7:0] parallel_data,
    output wire serial_out,
    output reg ack               // Acknowledge signal
);
    reg [7:0] shift_data;
    reg shifting;
    reg [2:0] bit_count;
    
    // Generate carry signals for efficient bit counter implementation
    wire [2:0] next_bit_count;
    wire carry;
    
    // Carry-lookahead logic for bit_count increment
    assign {carry, next_bit_count} = bit_count + 3'b001;
    
    always @(posedge clk) begin
        if (clear) begin
            shift_data <= 8'h00;
            ack <= 1'b0;
            shifting <= 1'b0;
            bit_count <= 3'b000;
        end
        else if (req && !shifting) begin
            // Load data when request is high and not currently shifting
            shift_data <= parallel_data;
            ack <= 1'b1;         // Acknowledge the request
            shifting <= 1'b1;
            bit_count <= 3'b000;
        end
        else if (shifting) begin
            if (bit_count == 3'b111) begin
                // Last bit has been shifted out
                shifting <= 1'b0;
                ack <= 1'b0;     // Clear acknowledge
            end
            else begin
                // Continue shifting
                shift_data <= {shift_data[6:0], 1'b0};
                bit_count <= next_bit_count;  // Use pre-computed next count
            end
        end
        else begin
            ack <= 1'b0;         // Clear acknowledge when not requested
        end
    end
    
    assign serial_out = shift_data[7];
endmodule
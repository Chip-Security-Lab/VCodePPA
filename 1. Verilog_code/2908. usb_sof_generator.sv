module usb_sof_generator(
    input wire clk,
    input wire rst_n,
    input wire sof_enable,
    input wire [10:0] frame_number_in,
    output reg [10:0] frame_number_out,
    output reg sof_valid,
    output reg [15:0] sof_packet
);
    reg [15:0] counter;
    reg sof_pending;
    
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            counter <= 16'd0;
            frame_number_out <= 11'd0;
            sof_valid <= 1'b0;
            sof_pending <= 1'b0;
            sof_packet <= 16'd0;
        end else begin
            // SOF generation every 1ms (assuming 48MHz clock)
            if (sof_enable) begin
                if (counter >= 16'd47999) begin
                    counter <= 16'd0;
                    frame_number_out <= frame_number_in + 11'd1;
                    sof_pending <= 1'b1;
                    
                    // Generate SOF packet: PID (SOF) + frame number + CRC5
                    sof_packet <= {5'b00000, frame_number_in + 11'd1}; // CRC calculation simplified
                end else begin
                    counter <= counter + 16'd1;
                end
            end
            
            // Output logic
            if (sof_pending) begin
                sof_valid <= 1'b1;
                sof_pending <= 1'b0;
            end else begin
                sof_valid <= 1'b0;
            end
        end
    end
endmodule
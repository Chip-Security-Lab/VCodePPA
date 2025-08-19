//SystemVerilog
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
    
    // 合并所有posedge clk or negedge rst_n触发的always块
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            counter <= 16'd0;
            frame_number_out <= 11'd0;
            sof_packet <= 16'd0;
            sof_valid <= 1'b0;
            sof_pending <= 1'b0;
        end else begin
            // Counter logic
            if (sof_enable) begin
                if (counter >= 16'd47999)
                    counter <= 16'd0;
                else
                    counter <= counter + 16'd1;
            end
            
            // Frame number and packet generation logic
            if (sof_enable && counter >= 16'd47999) begin
                frame_number_out <= frame_number_in + 11'd1;
                sof_packet <= {5'b00000, frame_number_in + 11'd1}; // CRC calculation simplified
                sof_pending <= 1'b1;
            end
            
            // Output control logic
            if (sof_pending) begin
                sof_valid <= 1'b1;
                sof_pending <= 1'b0;
            end else begin
                sof_valid <= 1'b0;
            end
        end
    end
    
endmodule
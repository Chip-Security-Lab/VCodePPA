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
    reg [5:0] byte_counter;
    reg broadcast_frame;
    reg [47:0] dest_mac;
    
    // Byte counter management
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            byte_counter <= 6'd0;
        end else if (frame_start) begin
            byte_counter <= 6'd0;
        end else if (data_valid && byte_counter < 6) begin
            byte_counter <= byte_counter + 1'b1;
        end
    end
    
    // Broadcast frame flag management
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            broadcast_frame <= 1'b0;
        end else if (frame_start) begin
            broadcast_frame <= 1'b0;
        end else if (data_valid && byte_counter < 6) begin
            if (byte_counter == 0) begin
                broadcast_frame <= (data_in == 8'hFF);
            end else if (data_in != 8'hFF) begin
                broadcast_frame <= 1'b0;
            end
        end
    end
    
    // Destination MAC address capture
    always @(posedge clk) begin
        if (data_valid && byte_counter < 6) begin
            dest_mac <= {dest_mac[39:0], data_in};
        end
    end
    
    // Broadcast detection status management
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            broadcast_detected <= 1'b0;
        end else if (frame_start) begin
            broadcast_detected <= 1'b0;
        end else if (data_valid && byte_counter == 5 && broadcast_frame) begin
            broadcast_detected <= 1'b1;
        end
    end
    
    // Data pass-through logic
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            data_out <= 8'h0;
        end else if (data_valid) begin
            data_out <= data_in;
        end
    end
    
    // Data valid output control
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            data_valid_out <= 1'b0;
        end else if (!data_valid) begin
            data_valid_out <= 1'b0;
        end else begin
            data_valid_out <= pass_broadcast || 
                             (byte_counter < 6 ? !broadcast_frame : !broadcast_detected);
        end
    end
    
endmodule
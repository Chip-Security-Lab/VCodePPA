//SystemVerilog
module eth_jumbo_frame_handler #(
    parameter STD_FRAME_SIZE = 1518,  // Standard Ethernet frame size
    parameter JUMBO_FRAME_SIZE = 9000 // Jumbo frame size limit
) (
    input wire clk,
    input wire reset,
    // Data input interface
    input wire [7:0] rx_data,
    input wire rx_valid,
    input wire frame_start,
    input wire frame_end,
    // Data output interface
    output reg [7:0] tx_data,
    output reg tx_valid,
    output reg frame_too_large,
    output reg jumbo_frame_detected
);
    // Retimed registers for control signals
    reg [13:0] byte_counter;
    reg std_frame_threshold_reached;
    reg jumbo_frame_threshold_reached;
    reg frame_too_large_internal;
    reg [7:0] rx_data_registered;
    
    // Register input data to break timing path
    always @(posedge clk or posedge reset) begin
        if (reset) begin
            rx_data_registered <= 8'h00;
        end else if (rx_valid) begin
            rx_data_registered <= rx_data;
        end
    end
    
    // Counter and threshold detection logic
    always @(posedge clk or posedge reset) begin
        if (reset) begin
            byte_counter <= 14'd0;
            std_frame_threshold_reached <= 1'b0;
            jumbo_frame_threshold_reached <= 1'b0;
            frame_too_large_internal <= 1'b0;
        end else begin
            if (frame_start) begin
                byte_counter <= 14'd0;
                std_frame_threshold_reached <= 1'b0;
                jumbo_frame_threshold_reached <= 1'b0;
                frame_too_large_internal <= 1'b0;
            end else if (rx_valid) begin
                byte_counter <= byte_counter + 1'b1;
                
                // Pre-compute threshold flags in separate registers
                if (byte_counter == STD_FRAME_SIZE - 1)
                    std_frame_threshold_reached <= 1'b1;
                    
                if (byte_counter == JUMBO_FRAME_SIZE - 1)
                    jumbo_frame_threshold_reached <= 1'b1;
                
                if (jumbo_frame_threshold_reached)
                    frame_too_large_internal <= 1'b1;
            end
        end
    end
    
    // Output stage with minimized combinational logic
    always @(posedge clk or posedge reset) begin
        if (reset) begin
            tx_data <= 8'h00;
            tx_valid <= 1'b0;
            frame_too_large <= 1'b0;
            jumbo_frame_detected <= 1'b0;
        end else begin
            // Set jumbo frame flag as soon as threshold is reached
            if (std_frame_threshold_reached && rx_valid)
                jumbo_frame_detected <= 1'b1;
            else if (frame_start)
                jumbo_frame_detected <= 1'b0;
                
            // Set frame too large flag based on pre-computed value
            if (frame_start)
                frame_too_large <= 1'b0;
            else if (jumbo_frame_threshold_reached && rx_valid)
                frame_too_large <= 1'b1;
                
            // Pass through data if not too large with minimal logic
            if (rx_valid && !frame_too_large_internal) begin
                tx_data <= rx_data_registered;
                tx_valid <= 1'b1;
            end else begin
                tx_valid <= 1'b0;
            end
            
            if (frame_end) begin
                tx_valid <= 1'b0;
            end
        end
    end
endmodule
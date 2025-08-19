//SystemVerilog
//ieee:1364-2005
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
    reg [13:0] byte_counter;
    reg [13:0] byte_counter_buf1, byte_counter_buf2;
    
    // Buffered control signals
    reg frame_start_buf, frame_end_buf;
    reg rx_valid_buf;
    reg [7:0] rx_data_buf;
    
    // Size threshold flags with buffering
    reg std_size_reached, jumbo_size_reached;
    reg std_size_reached_buf, jumbo_size_reached_buf;
    
    // High fanout comparator signals
    wire b0, b1;
    reg b0_buf1, b0_buf2, b0_buf3;
    reg b1_buf1, b1_buf2, b1_buf3;
    
    // First stage: Input registration and comparison
    always @(posedge clk or posedge reset) begin
        if (reset) begin
            byte_counter <= 14'd0;
            frame_start_buf <= 1'b0;
            frame_end_buf <= 1'b0;
            rx_valid_buf <= 1'b0;
            rx_data_buf <= 8'h00;
            std_size_reached <= 1'b0;
            jumbo_size_reached <= 1'b0;
        end else begin
            // Register inputs to reduce input load
            frame_start_buf <= frame_start;
            frame_end_buf <= frame_end;
            rx_valid_buf <= rx_valid;
            rx_data_buf <= rx_data;
            
            // Counter logic with reset
            case (1'b1)
                frame_start_buf: byte_counter <= 14'd0;
                rx_valid_buf: byte_counter <= byte_counter + 1'b1;
                default: byte_counter <= byte_counter;
            endcase
            
            // Size threshold comparisons
            std_size_reached <= (byte_counter == STD_FRAME_SIZE - 1) && rx_valid_buf;
            jumbo_size_reached <= (byte_counter == JUMBO_FRAME_SIZE - 1) && rx_valid_buf;
        end
    end
    
    // Assign comparator outputs
    assign b0 = (byte_counter == STD_FRAME_SIZE);
    assign b1 = (byte_counter >= JUMBO_FRAME_SIZE);
    
    // Second stage: Buffer high fanout signals
    always @(posedge clk or posedge reset) begin
        if (reset) begin
            byte_counter_buf1 <= 14'd0;
            byte_counter_buf2 <= 14'd0;
            b0_buf1 <= 1'b0;
            b0_buf2 <= 1'b0;
            b0_buf3 <= 1'b0;
            b1_buf1 <= 1'b0;
            b1_buf2 <= 1'b0;
            b1_buf3 <= 1'b0;
            std_size_reached_buf <= 1'b0;
            jumbo_size_reached_buf <= 1'b0;
        end else begin
            // Buffer byte counter for different consumers
            byte_counter_buf1 <= byte_counter;
            byte_counter_buf2 <= byte_counter;
            
            // Buffer comparison results
            b0_buf1 <= b0;
            b0_buf2 <= b0;
            b0_buf3 <= b0;
            
            b1_buf1 <= b1;
            b1_buf2 <= b1;
            b1_buf3 <= b1;
            
            // Buffer threshold flags
            std_size_reached_buf <= std_size_reached;
            jumbo_size_reached_buf <= jumbo_size_reached;
        end
    end
    
    // Third stage: Output logic
    always @(posedge clk or posedge reset) begin
        if (reset) begin
            tx_data <= 8'h00;
            tx_valid <= 1'b0;
            frame_too_large <= 1'b0;
            jumbo_frame_detected <= 1'b0;
        end else begin
            // Use case statement for frame events
            case (1'b1)
                frame_start_buf: begin
                    frame_too_large <= 1'b0;
                    jumbo_frame_detected <= 1'b0;
                    tx_valid <= rx_valid_buf ? 1'b1 : 1'b0;
                    tx_data <= rx_valid_buf ? rx_data_buf : tx_data;
                end
                
                std_size_reached_buf: begin
                    jumbo_frame_detected <= 1'b1;
                    tx_valid <= rx_valid_buf && !frame_too_large ? 1'b1 : 1'b0;
                    tx_data <= rx_valid_buf && !frame_too_large ? rx_data_buf : tx_data;
                end
                
                jumbo_size_reached_buf: begin
                    frame_too_large <= 1'b1;
                    tx_valid <= 1'b0;
                    tx_data <= tx_data;
                end
                
                frame_end_buf: begin
                    tx_valid <= 1'b0;
                    tx_data <= tx_data;
                end
                
                rx_valid_buf: begin
                    tx_valid <= !frame_too_large ? 1'b1 : 1'b0;
                    tx_data <= !frame_too_large ? rx_data_buf : tx_data;
                end
                
                default: begin
                    tx_valid <= 1'b0;
                    tx_data <= tx_data;
                end
            endcase
        end
    end
endmodule
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
    // Registered input signals
    reg [7:0] rx_data_reg;
    reg rx_valid_reg;
    reg frame_start_reg;
    reg frame_end_reg;
    
    // Frame tracking counter
    reg [13:0] byte_counter;
    
    // Pipeline stage 1 registers - break up combinational paths
    reg [13:0] next_byte_counter_p1;
    reg rx_valid_p1, frame_start_p1;
    
    // Pipeline stage 2 registers for complex conditions
    reg std_frame_exceeded;
    reg jumbo_frame_exceeded;
    
    // Output control signals
    reg next_jumbo_detected;
    reg next_frame_too_large;
    reg next_tx_valid;
    
    // Register input signals first (forward retiming)
    always @(posedge clk or posedge reset) begin
        if (reset) begin
            rx_data_reg <= 8'h00;
            rx_valid_reg <= 1'b0;
            frame_start_reg <= 1'b0;
            frame_end_reg <= 1'b0;
        end else begin
            rx_data_reg <= rx_data;
            rx_valid_reg <= rx_valid;
            frame_start_reg <= frame_start;
            frame_end_reg <= frame_end;
        end
    end
    
    // Pipeline stage 1: byte counter calculation
    always @(posedge clk or posedge reset) begin
        if (reset) begin
            next_byte_counter_p1 <= 14'd0;
            rx_valid_p1 <= 1'b0;
            frame_start_p1 <= 1'b0;
        end else begin
            // Next byte counter logic (simplified)
            if (frame_start_reg) begin
                next_byte_counter_p1 <= 14'd0;
            end else if (rx_valid_reg) begin
                next_byte_counter_p1 <= byte_counter + 1'b1;
            end else begin
                next_byte_counter_p1 <= byte_counter;
            end
            
            // Pass signals to next pipeline stage
            rx_valid_p1 <= rx_valid_reg;
            frame_start_p1 <= frame_start_reg;
        end
    end
    
    // Pipeline stage 2: frame size comparison
    always @(posedge clk or posedge reset) begin
        if (reset) begin
            std_frame_exceeded <= 1'b0;
            jumbo_frame_exceeded <= 1'b0;
        end else begin
            // Check if standard frame size is exceeded
            std_frame_exceeded <= (next_byte_counter_p1 == STD_FRAME_SIZE) && rx_valid_p1;
            
            // Check if jumbo frame size is exceeded
            jumbo_frame_exceeded <= (next_byte_counter_p1 >= JUMBO_FRAME_SIZE) && rx_valid_p1;
        end
    end
    
    // Combinational logic for next state calculation (reduced complexity)
    always @(*) begin
        // Next jumbo detected logic
        if (frame_start_p1) begin
            next_jumbo_detected = 1'b0;
        end else if (std_frame_exceeded) begin
            next_jumbo_detected = 1'b1;
        end else begin
            next_jumbo_detected = jumbo_frame_detected;
        end
        
        // Next frame too large logic
        if (frame_start_p1) begin
            next_frame_too_large = 1'b0;
        end else if (jumbo_frame_exceeded) begin
            next_frame_too_large = 1'b1;
        end else begin
            next_frame_too_large = frame_too_large;
        end
        
        // Next tx valid logic
        next_tx_valid = rx_valid_p1 && !next_frame_too_large;
    end
    
    // Main state and output registers
    always @(posedge clk or posedge reset) begin
        if (reset) begin
            byte_counter <= 14'd0;
            jumbo_frame_detected <= 1'b0;
            frame_too_large <= 1'b0;
            tx_data <= 8'h00;
            tx_valid <= 1'b0;
        end else begin
            // Update state registers
            byte_counter <= next_byte_counter_p1;
            jumbo_frame_detected <= next_jumbo_detected;
            frame_too_large <= next_frame_too_large;
            
            // Update output data
            if (rx_valid_p1 && !next_frame_too_large) begin
                tx_data <= rx_data_reg;
            end
            
            // Handle tx_valid with frame_end priority
            if (frame_end_reg) begin
                tx_valid <= 1'b0;
            end else begin
                tx_valid <= next_tx_valid;
            end
        end
    end
endmodule
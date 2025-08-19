//SystemVerilog
module ps2_codec (
    input  wire       clk_ps2,    // PS2 clock input
    input  wire       data,       // PS2 data input
    input  wire       ready,      // Ready signal - receiver is ready to accept data
    output reg        valid,      // Valid signal - valid data is available
    output reg  [7:0] keycode,    // Decoded key code
    output reg        parity_ok   // Parity check result
);

    // Data capture pipeline stage
    reg [10:0] shift_reg;
    reg        frame_complete;
    
    // Data processing pipeline stage
    reg [7:0]  captured_data;
    reg        captured_parity;
    reg        start_bit;
    reg        stop_bit;
    
    // Handshaking control
    reg        data_pending;
    
    // Frame capture logic - first pipeline stage
    always @(negedge clk_ps2) begin
        // Shift register captures incoming bits (start, data[7:0], parity, stop)
        shift_reg <= {data, shift_reg[10:1]};
        
        // Detect when a complete frame has been received (when stop bit reaches bit 0)
        frame_complete <= shift_reg[0];
    end
    
    // Data processing and handshaking logic
    always @(posedge clk_ps2) begin
        // Default valid signal assignment
        valid <= 1'b0;
        
        if (frame_complete && !data_pending) begin
            // Extract components from the shift register
            captured_data   <= shift_reg[8:1];   // 8 data bits
            captured_parity <= shift_reg[9];     // Parity bit
            start_bit       <= shift_reg[10];    // Start bit (should be 0)
            stop_bit        <= shift_reg[0];     // Stop bit (should be 1)
            
            // Calculate parity
            parity_ok <= (^shift_reg[8:1] == shift_reg[9]);
            keycode   <= shift_reg[8:1];
            
            // Set valid high to indicate new data is available
            valid <= 1'b1;
            data_pending <= 1'b1;
        end
        else if (data_pending && ready) begin
            // Data has been acknowledged, clear pending flag
            data_pending <= 1'b0;
        end
        else if (data_pending) begin
            // Keep asserting valid until receiver acknowledges
            valid <= 1'b1;
        end
    end

endmodule
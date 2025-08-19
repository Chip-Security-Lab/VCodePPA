//SystemVerilog
///////////////////////////////////////////////////////////////////////////////
// File: manchester_codec.v
// Description: Manchester encoder/decoder with optimized path balancing
// Standard: IEEE 1364-2005 Verilog
///////////////////////////////////////////////////////////////////////////////

module manchester_codec (
    input  wire clk,            // System clock
    input  wire rst,            // Active high reset
    input  wire encode_en,      // Encoder enable
    input  wire decode_en,      // Decoder enable
    input  wire data_in,        // Input data for encoding
    input  wire manchester_in,  // Manchester encoded input for decoding
    output reg  manchester_out, // Manchester encoded output
    output reg  data_out,       // Decoded data output
    output reg  data_valid      // Indicates valid decoded data
);

    //-------------------------------------------------------------------------
    // Clock divider and phase generation - optimized with parallel logic
    //-------------------------------------------------------------------------
    reg [1:0] bit_phase_counter;
    reg phase_mid_bit_reg;
    reg phase_bit_edge_reg;
    
    always @(posedge clk) begin
        if (rst) begin
            bit_phase_counter <= 2'b00;
            phase_mid_bit_reg <= 1'b0;
            phase_bit_edge_reg <= 1'b0;
        end else begin
            bit_phase_counter <= bit_phase_counter + 1'b1;
            // Pre-compute phase signals to reduce critical path delay
            phase_mid_bit_reg <= (bit_phase_counter + 1'b1) == 2'b01;
            phase_bit_edge_reg <= (bit_phase_counter + 1'b1) == 2'b00;
        end
    end
    
    // Use registered phase signals to reduce fanout and improve timing
    wire phase_mid_bit = phase_mid_bit_reg;
    wire phase_bit_edge = phase_bit_edge_reg;
    
    //-------------------------------------------------------------------------
    // Encoder data path - optimized pipeline
    //-------------------------------------------------------------------------
    reg data_in_latched;
    reg encode_active;
    reg next_manchester_out;
    
    always @(posedge clk) begin
        if (rst) begin
            data_in_latched <= 1'b0;
            encode_active <= 1'b0;
            manchester_out <= 1'b0;
        end else begin
            // Capture input at bit boundaries for stable encoding
            if (phase_bit_edge) begin
                data_in_latched <= data_in;
                encode_active <= encode_en;
            end
            
            // Pre-compute manchester output for next cycle
            manchester_out <= next_manchester_out;
        end
    end
    
    // Break long combinational path by separating manchester output logic
    always @(*) begin
        if (encode_active) begin
            // Manchester encoding logic with reduced critical path
            next_manchester_out = bit_phase_counter[0] ? ~data_in_latched : data_in_latched;
        end else begin
            next_manchester_out = 1'b0;
        end
    end
    
    //-------------------------------------------------------------------------
    // Decoder data path - optimized sampling with parallel detection
    //-------------------------------------------------------------------------
    reg manchester_in_prev;
    reg manchester_in_curr;
    reg transition_detected;
    reg next_data_out;
    reg next_data_valid;
    
    always @(posedge clk) begin
        if (rst) begin
            manchester_in_prev <= 1'b0;
            manchester_in_curr <= 1'b0;
            transition_detected <= 1'b0;
            data_out <= 1'b0;
            data_valid <= 1'b0;
        end else begin
            if (decode_en) begin
                // Sample the input every clock cycle
                manchester_in_prev <= manchester_in_curr;
                manchester_in_curr <= manchester_in;
                
                // Detect transition and determine data in parallel
                if (phase_mid_bit) begin
                    transition_detected <= (manchester_in_curr != manchester_in_prev);
                    data_out <= next_data_out;
                end
                
                // Update valid signal with pre-computed value
                data_valid <= next_data_valid;
            end else begin
                data_valid <= 1'b0;
            end
        end
    end
    
    // Separated combinational logic to balance paths
    always @(*) begin
        // Pre-compute transition detection output
        next_data_out = (manchester_in_curr != manchester_in_prev) ? 1'b1 : 1'b0;
        
        // Pre-compute data valid logic
        next_data_valid = decode_en & phase_mid_bit;
    end

endmodule
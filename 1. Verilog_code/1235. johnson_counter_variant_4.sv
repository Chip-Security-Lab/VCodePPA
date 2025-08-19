//SystemVerilog
module johnson_counter (
    // Clock and reset
    input wire clk,
    input wire rst,
    
    // AXI-Stream input interface
    input wire s_axis_tvalid,
    output wire s_axis_tready,
    
    // AXI-Stream output interface
    output wire m_axis_tvalid,
    input wire m_axis_tready,
    output wire [3:0] m_axis_tdata,
    output wire m_axis_tlast
);
    // Internal signals
    reg [3:0] q;
    reg next_bit;
    reg output_valid;
    reg cycle_complete;
    reg [2:0] counter;
    
    // Input ready signal - always ready to accept new transactions when not in reset
    assign s_axis_tready = ~rst;
    
    // Output valid signal
    assign m_axis_tvalid = output_valid;
    
    // Output data
    assign m_axis_tdata = q;
    
    // TLAST signal - assert when counter completes a full cycle (8 states)
    assign m_axis_tlast = cycle_complete;
    
    // State logic control - lookup table based approach
    reg update_state;
    reg [3:0] next_state_index;
    wire [7:0] control_lut_input;
    reg [5:0] control_lut_output;
    
    // Control LUT input generation
    assign control_lut_input = {
        rst,                          // bit 7
        s_axis_tvalid,                // bit 6
        output_valid,                 // bit 5
        m_axis_tready,                // bit 4
        counter == 3'b111,            // bit 3
        1'b0,                         // bit 2 (reserved)
        1'b0,                         // bit 1 (reserved)
        1'b0                          // bit 0 (reserved)
    };
    
    // Control lookup table logic
    // [0]: update_state
    // [1]: clear_valid
    // [2]: set_valid
    // [3]: reset_counter
    // [4]: increment_counter
    // [5]: set_cycle_complete
    always @(*) begin
        casez (control_lut_input[7:4])
            // Reset state
            4'b1???: control_lut_output = 6'b000000;
            
            // Valid input and not valid output
            4'b01?0: control_lut_output = 6'b100100;
            
            // Valid input and valid output, downstream ready
            4'b0111: control_lut_output = 6'b100100;
            
            // No valid input but valid output, downstream ready
            4'b0011: control_lut_output = 6'b010000;
            
            // Valid output but downstream not ready
            4'b0110: control_lut_output = 6'b000000;
            
            // Default case
            default: control_lut_output = 6'b000000;
        endcase
    end
    
    // Counter state lookup table
    reg [3:0] next_counter_state;
    always @(*) begin
        if (control_lut_output[3]) begin
            // Reset counter
            next_counter_state = 3'b000;
        end else if (control_lut_output[4]) begin
            // Increment counter
            next_counter_state = counter + 1'b1;
        end else begin
            // Hold value
            next_counter_state = counter;
        end
    end
    
    // Actual Johnson counter implementation
    always @(posedge clk) begin
        if (rst) begin
            q <= 4'b0000;
            next_bit <= 1'b0;
            output_valid <= 1'b0;
            cycle_complete <= 1'b0;
            counter <= 3'b000;
        end else begin
            // Pre-compute next bit for forward retiming regardless of state
            next_bit <= ~q[3];
            
            // Update state based on lookup table control signals
            if (control_lut_output[0]) begin
                // Update state
                q <= {q[2:0], next_bit};
                counter <= next_counter_state;
            end
            
            // Handle output valid flag
            if (control_lut_output[1]) begin
                output_valid <= 1'b0;
            end else if (control_lut_output[2]) begin
                output_valid <= 1'b1;
            end
            
            // Handle cycle complete flag
            if (control_lut_output[1]) begin
                cycle_complete <= 1'b0;
            end else if (control_lut_output[5] || (counter == 3'b111 && control_lut_output[0])) begin
                cycle_complete <= 1'b1;
            end
        end
    end
endmodule
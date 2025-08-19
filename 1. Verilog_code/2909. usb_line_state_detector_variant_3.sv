//SystemVerilog IEEE 1364-2005
module usb_line_state_detector(
    input  wire        clk,
    input  wire        rst_n,
    
    // AXI-Stream slave interface
    input  wire        s_axis_tvalid,
    output wire        s_axis_tready,
    input  wire [1:0]  s_axis_tdata,  // {dp, dm}
    input  wire        s_axis_tlast,  // Indicates end of packet
    
    // AXI-Stream master interface
    output wire        m_axis_tvalid,
    input  wire        m_axis_tready,
    output wire [7:0]  m_axis_tdata,  // Line state and flags
    output wire        m_axis_tlast   // Indicates end of state processing
);
    localparam J_STATE = 2'b01, K_STATE = 2'b10, SE0 = 2'b00, SE1 = 2'b11;
    
    reg [7:0] reset_counter;
    reg [1:0] curr_line_state;
    reg [1:0] line_state;
    reg j_state, k_state, se0_state, se1_state, reset_detected;
    
    // State machine for processing
    reg processing_state;
    reg output_valid;
    
    // AXI Stream handshaking logic
    assign s_axis_tready = !processing_state || m_axis_tready;
    assign m_axis_tvalid = output_valid;
    assign m_axis_tlast = s_axis_tlast;
    
    // Pack output data
    assign m_axis_tdata = {reset_detected, se1_state, se0_state, k_state, j_state, line_state};
    
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            curr_line_state <= J_STATE;
            line_state <= J_STATE;
            j_state <= 1'b0;
            k_state <= 1'b0;
            se0_state <= 1'b0;
            se1_state <= 1'b0;
            reset_counter <= 8'd0;
            reset_detected <= 1'b0;
            processing_state <= 1'b0;
            output_valid <= 1'b0;
        end else begin
            // Default state for output_valid
            output_valid <= 1'b0;
            
            if (s_axis_tvalid && s_axis_tready) begin
                // Capture the current line state from AXI-Stream input
                curr_line_state = s_axis_tdata;
                line_state <= curr_line_state;
                processing_state <= 1'b1;
                
                // Optimize state decoding with parallel case construct and priority-based checks
                case (curr_line_state)
                    SE0: begin 
                        se0_state <= 1'b1;
                        se1_state <= 1'b0;
                        j_state <= 1'b0;
                        k_state <= 1'b0;
                        
                        // Reset detection logic optimized
                        if (reset_counter < 8'd255)
                            reset_counter <= reset_counter + 8'd1;
                        reset_detected <= (reset_counter >= 8'd120); // Direct comparison eliminates IF
                    end
                    J_STATE: begin
                        se0_state <= 1'b0;
                        se1_state <= 1'b0;
                        j_state <= 1'b1;
                        k_state <= 1'b0;
                        reset_counter <= 8'd0;
                        reset_detected <= 1'b0;
                    end
                    K_STATE: begin
                        se0_state <= 1'b0;
                        se1_state <= 1'b0;
                        j_state <= 1'b0;
                        k_state <= 1'b1;
                        reset_counter <= 8'd0;
                        reset_detected <= 1'b0;
                    end
                    SE1: begin
                        se0_state <= 1'b0;
                        se1_state <= 1'b1;
                        j_state <= 1'b0;
                        k_state <= 1'b0;
                        reset_counter <= 8'd0;
                        reset_detected <= 1'b0;
                    end
                endcase
                
                // Indicate data is ready for output
                output_valid <= 1'b1;
            end
            
            // Clear processing state when output is accepted
            if (output_valid && m_axis_tready) begin
                processing_state <= 1'b0;
            end
        end
    end
endmodule
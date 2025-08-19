//SystemVerilog
module pulse_demux (
    input wire clk,                      // System clock
    input wire aresetn,                  // Active low reset
    
    // AXI-Stream slave interface
    input wire [3:0] s_axis_tdata,       // Input data
    input wire s_axis_tvalid,            // Input valid signal
    output wire s_axis_tready,           // Ready to accept data
    
    // AXI-Stream master interface
    output wire [3:0] m_axis_tdata,      // Output data
    output wire m_axis_tvalid,           // Output valid signal
    input wire m_axis_tready,            // Downstream ready
    output wire m_axis_tlast             // End of packet signal
);

    // Stage 1 registers
    reg [1:0] route_sel;                 // Route selection register
    reg s_valid_reg;                     // Registered input valid
    reg [3:0] s_data_reg;                // Registered input data
    reg s_ready_reg;                     // Registered ready signal
    
    // Stage 2 registers
    reg pulse_detected;                  // Pulse detection register
    reg [1:0] route_sel_pipe;            // Pipelined route selection
    reg pulse_valid_pipe;                // Pipelined pulse valid
    
    // Output stage registers
    reg [3:0] pulse_out;                 // Output pulse register
    
    // Connect output signals
    assign m_axis_tdata = pulse_out;
    assign m_axis_tvalid = |pulse_out;   // Valid when any output bit is active
    assign m_axis_tlast = 1'b1;          // Each pulse is a complete transaction
    assign s_axis_tready = m_axis_tready; // Ready to accept data
    
    // Stage 1: Register input signals
    always @(posedge clk or negedge aresetn) begin
        if (!aresetn) begin
            s_valid_reg <= 1'b0;
            s_data_reg <= 4'b0;
            s_ready_reg <= 1'b0;
        end else begin
            s_valid_reg <= s_axis_tvalid;
            s_data_reg <= s_axis_tdata;
            s_ready_reg <= m_axis_tready;
        end
    end
    
    // Stage 2: Process route selection and pulse detection
    always @(posedge clk or negedge aresetn) begin
        if (!aresetn) begin
            route_sel <= 2'b00;
            route_sel_pipe <= 2'b00;
            pulse_detected <= 1'b0;
            pulse_valid_pipe <= 1'b0;
        end else begin
            // Capture route selection from incoming data
            if (s_axis_tvalid && s_axis_tready) begin
                route_sel <= s_axis_tdata[1:0];
            end
            
            // Pipeline route selection
            route_sel_pipe <= route_sel;
            
            // Edge detection for input pulse
            pulse_detected <= s_axis_tvalid && s_axis_tready;
            
            // Pipeline pulse valid condition
            pulse_valid_pipe <= s_axis_tvalid && s_axis_tready && !pulse_detected;
        end
    end
    
    // Stage 3: Output generation
    always @(posedge clk or negedge aresetn) begin
        if (!aresetn) begin
            pulse_out <= 4'b0000;
        end else begin
            // Distribute pulse to selected output when AXI handshake occurs
            if (m_axis_tready) begin
                pulse_out <= 4'b0;
                if (pulse_valid_pipe)
                    pulse_out[route_sel_pipe] <= 1'b1;
            end
        end
    end
    
endmodule
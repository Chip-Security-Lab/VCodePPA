//SystemVerilog
module can_bus_monitor (
  // Clock and reset
  input  wire        aclk,
  input  wire        aresetn,
  
  // Input AXI-Stream interface
  input  wire        s_axis_tvalid,
  output wire        s_axis_tready,
  input  wire [31:0] s_axis_tdata,
  input  wire        s_axis_tlast,
  
  // Output AXI-Stream interface
  output wire        m_axis_tvalid,
  input  wire        m_axis_tready,
  output wire [31:0] m_axis_tdata,
  output wire        m_axis_tlast
);

  // Internal signals and registers
  reg [15:0] frames_received;
  reg [15:0] errors_detected;
  reg [15:0] bus_load_percent;
  reg [7:0]  last_error_type;
  reg [31:0] total_bits, active_bits;
  reg        prev_frame_valid, prev_error;
  
  // Extract input signals from AXI-Stream - pure combinational logic
  wire        can_rx         = s_axis_tdata[0];
  wire        can_tx         = s_axis_tdata[1];
  wire        frame_valid    = s_axis_tdata[2];
  wire        error_detected = s_axis_tdata[3];
  wire [10:0] rx_id          = s_axis_tdata[14:4];
  wire [3:0]  rx_dlc         = s_axis_tdata[18:15];
  
  // Always ready to receive data - pure combinational
  assign s_axis_tready = 1'b1;
  
  // Output registers
  reg        output_valid_reg;
  reg [31:0] output_data_reg;
  reg        output_last_reg;
  
  // Output assignments - pure combinational
  assign m_axis_tvalid = output_valid_reg;
  assign m_axis_tdata = output_data_reg;
  assign m_axis_tlast = output_last_reg;
  
  // Combinational logic signals
  wire frame_start = !prev_frame_valid && frame_valid;
  wire error_start = !prev_error && error_detected;
  wire should_update_bus_load = (total_bits >= 32'd1000);
  
  // Bus load percentage calculation - converted from ternary to wire+logic
  reg [15:0] new_bus_load_percent;
  
  always @(*) begin
    if (total_bits >= 32'd1000) begin
      new_bus_load_percent = ((active_bits * 16'd100) / total_bits);
    end else begin
      new_bus_load_percent = bus_load_percent;
    end
  end
  
  // Next state calculations - converted from ternary to reg+logic
  reg [15:0] next_frames_received;
  reg [15:0] next_errors_detected;
  reg [31:0] next_total_bits;
  reg [31:0] next_active_bits;
  
  always @(*) begin
    // Frame counter logic
    if (frame_start) begin
      next_frames_received = frames_received + 16'h1;
    end else begin
      next_frames_received = frames_received;
    end
    
    // Error counter logic
    if (error_start) begin
      next_errors_detected = errors_detected + 16'h1;
    end else begin
      next_errors_detected = errors_detected;
    end
    
    // Total bits counter logic
    if (should_update_bus_load) begin
      next_total_bits = 32'h0;
    end else if (s_axis_tvalid) begin
      next_total_bits = total_bits + 32'h1;
    end else begin
      next_total_bits = total_bits;
    end
    
    // Active bits counter logic
    if (should_update_bus_load) begin
      next_active_bits = 32'h0;
    end else if (s_axis_tvalid && !can_rx) begin
      next_active_bits = active_bits + 32'h1;
    end else begin
      next_active_bits = active_bits;
    end
  end
  
  // Output preparation logic - converted from ternary to reg+logic
  reg next_output_valid;
  reg [31:0] next_output_data;
  reg next_output_last;
  
  always @(*) begin
    // Output valid logic
    if (s_axis_tvalid) begin
      next_output_valid = 1'b1;
    end else if (m_axis_tready && output_valid_reg) begin
      next_output_valid = 1'b0;
    end else begin
      next_output_valid = output_valid_reg;
    end
    
    // Output data logic
    if (s_axis_tvalid) begin
      next_output_data = {new_bus_load_percent, last_error_type, next_errors_detected, next_frames_received};
    end else begin
      next_output_data = output_data_reg;
    end
    
    // Output last logic
    if (s_axis_tvalid) begin
      next_output_last = s_axis_tlast;
    end else begin
      next_output_last = output_last_reg;
    end
  end

  // Sequential logic - all registers updated here
  always @(posedge aclk or negedge aresetn) begin
    if (!aresetn) begin
      // Reset all registers
      frames_received <= 16'h0;
      errors_detected <= 16'h0;
      bus_load_percent <= 16'h0;
      last_error_type <= 8'h0;
      total_bits <= 32'h0;
      active_bits <= 32'h0;
      prev_frame_valid <= 1'b0;
      prev_error <= 1'b0;
      output_valid_reg <= 1'b0;
      output_data_reg <= 32'h0;
      output_last_reg <= 1'b0;
    end else begin
      // Update all registers with next state values
      prev_frame_valid <= frame_valid;
      prev_error <= error_detected;
      
      // Update counters when valid input
      if (s_axis_tvalid) begin
        frames_received <= next_frames_received;
        errors_detected <= next_errors_detected;
        
        // Update bits counters
        total_bits <= next_total_bits;
        active_bits <= next_active_bits;
        
        // Update bus load percentage if needed
        if (should_update_bus_load) begin
          bus_load_percent <= new_bus_load_percent;
        end
      end
      
      // Handle output registers
      output_valid_reg <= next_output_valid;
      output_data_reg <= next_output_data;
      output_last_reg <= next_output_last;
    end
  end

endmodule
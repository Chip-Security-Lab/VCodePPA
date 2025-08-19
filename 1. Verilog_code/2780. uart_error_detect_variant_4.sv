//SystemVerilog
module uart_error_detect (
  // Clock and Reset
  input  wire        aclk,
  input  wire        aresetn,
  
  // Input UART interface
  input  wire        serial_in,
  
  // Output AXI-Stream interface
  output wire [7:0]  m_axis_tdata,
  output wire        m_axis_tvalid,
  input  wire        m_axis_tready,
  output wire        m_axis_tlast,
  
  // Error indicators as AXI-Stream side-channel information
  output wire [2:0]  m_axis_tuser
);
  
  // States definition
  localparam IDLE = 3'd0, START = 3'd1, DATA_0 = 3'd2, DATA_1 = 3'd3, 
             DATA_2 = 3'd4, DATA_3 = 3'd5, PARITY = 3'd6, STOP = 3'd7;
  
  // Internal registers - Pipeline stage 1 (Detection)
  reg [2:0]  state_s1;
  reg [2:0]  bit_count_s1;
  reg [3:0]  shift_reg_low_s1;  // Lower 4 bits
  reg        parity_accum_s1;
  
  // Internal registers - Pipeline stage 2 (Processing)
  reg [2:0]  state_s2;
  reg [3:0]  shift_reg_high_s2; // Upper 4 bits
  reg        parity_accum_s2;
  
  // Internal registers - Pipeline stage 3 (Error Detection)
  reg [7:0]  full_data_s3;      // Combined shift register
  reg        parity_bit_s3;
  reg        parity_error_pending_s3;
  reg        framing_error_pending_s3;
  
  // Internal registers - Pipeline stage 4 (Data Validation)
  reg [7:0]  rx_data_reg_s4;
  reg        framing_error_reg_s4;
  reg        parity_error_reg_s4;
  reg        overrun_error_reg_s4;
  reg        data_ready_s4;
  reg        prev_data_ready_s4;
  
  // AXI-Stream output stage
  reg [7:0]  rx_data_out;
  reg [2:0]  error_flags_out;
  reg        m_axis_tvalid_reg;
  
  // Map internal signals to AXI-Stream outputs
  assign m_axis_tdata  = rx_data_out;
  assign m_axis_tvalid = m_axis_tvalid_reg;
  assign m_axis_tlast  = 1'b1; // Each byte is treated as end of packet
  assign m_axis_tuser  = error_flags_out;
  
  // Stage 1: Bit detection and initial processing
  always @(posedge aclk or negedge aresetn) begin
    if (!aresetn) begin
      state_s1 <= IDLE;
      bit_count_s1 <= 0;
      shift_reg_low_s1 <= 0;
      parity_accum_s1 <= 0;
    end else begin
      case (state_s1)
        IDLE: begin
          if (serial_in == 1'b0) begin
            state_s1 <= START;
            parity_accum_s1 <= 0;
          end
        end
        
        START: begin
          state_s1 <= DATA_0;
          bit_count_s1 <= 0;
          shift_reg_low_s1 <= 0;
        end
        
        DATA_0: begin
          // Process first 4 bits
          shift_reg_low_s1 <= {serial_in, shift_reg_low_s1[3:1]};
          parity_accum_s1 <= parity_accum_s1 ^ serial_in;
          
          if (bit_count_s1 == 3) begin
            state_s1 <= DATA_1;
            bit_count_s1 <= 0;
          end else begin
            bit_count_s1 <= bit_count_s1 + 1;
          end
        end
        
        DATA_1: begin
          // Process upper 4 bits in stage 1
          shift_reg_low_s1 <= {serial_in, shift_reg_low_s1[3:1]};
          parity_accum_s1 <= parity_accum_s1 ^ serial_in;
          
          if (bit_count_s1 == 3) begin
            state_s1 <= PARITY;
          end else begin
            bit_count_s1 <= bit_count_s1 + 1;
          end
        end
        
        PARITY: begin
          state_s1 <= STOP;
          parity_accum_s1 <= parity_accum_s1 ^ serial_in; // Final parity calculation
        end
        
        STOP: begin
          state_s1 <= IDLE;
        end
        
        default: state_s1 <= IDLE;
      endcase
    end
  end
  
  // Stage 2: Data assembly and continuation of processing
  always @(posedge aclk or negedge aresetn) begin
    if (!aresetn) begin
      state_s2 <= IDLE;
      shift_reg_high_s2 <= 0;
      parity_accum_s2 <= 0;
    end else begin
      state_s2 <= state_s1;
      
      if (state_s1 == DATA_0 && bit_count_s1 == 3) begin
        // Transfer lower 4 bits to stage 2
        shift_reg_high_s2 <= shift_reg_low_s1;
        parity_accum_s2 <= parity_accum_s1;
      end
    end
  end
  
  // Stage 3: Error detection and data preparation
  always @(posedge aclk or negedge aresetn) begin
    if (!aresetn) begin
      full_data_s3 <= 0;
      parity_bit_s3 <= 0;
      parity_error_pending_s3 <= 0;
      framing_error_pending_s3 <= 0;
    end else begin
      // Assemble full data when second stage of data is complete
      if (state_s2 == DATA_1 && state_s1 == PARITY) begin
        full_data_s3 <= {shift_reg_low_s1, shift_reg_high_s2};
      end
      
      // Capture parity bit
      if (state_s2 == PARITY) begin
        parity_bit_s3 <= parity_accum_s2;
      end
      
      // Check for parity error
      if (state_s2 == STOP) begin
        parity_error_pending_s3 <= (parity_bit_s3 == serial_in); // Odd parity check
        framing_error_pending_s3 <= (serial_in == 0); // STOP bit should be 1
      end
    end
  end
  
  // Stage 4: Data validation and error flag finalization
  always @(posedge aclk or negedge aresetn) begin
    if (!aresetn) begin
      rx_data_reg_s4 <= 0;
      framing_error_reg_s4 <= 0;
      parity_error_reg_s4 <= 0;
      overrun_error_reg_s4 <= 0;
      data_ready_s4 <= 0;
      prev_data_ready_s4 <= 0;
    end else begin
      prev_data_ready_s4 <= data_ready_s4;
      
      if (state_s2 == STOP) begin
        rx_data_reg_s4 <= full_data_s3;
        framing_error_reg_s4 <= framing_error_pending_s3;
        parity_error_reg_s4 <= parity_error_pending_s3;
        
        // Check for overrun
        overrun_error_reg_s4 <= data_ready_s4 && !prev_data_ready_s4 && m_axis_tvalid_reg;
        data_ready_s4 <= 1'b1;
      end else if (data_ready_s4 && prev_data_ready_s4 && m_axis_tvalid_reg && m_axis_tready) begin
        data_ready_s4 <= 1'b0;
      end
    end
  end
  
  // Output stage: AXI-Stream interface management
  always @(posedge aclk or negedge aresetn) begin
    if (!aresetn) begin
      rx_data_out <= 0;
      error_flags_out <= 0;
      m_axis_tvalid_reg <= 0;
    end else begin
      // Handle AXI-Stream handshake
      if (m_axis_tvalid_reg && m_axis_tready) begin
        m_axis_tvalid_reg <= 1'b0; // Clear valid after handshake
      end
      
      // Data is ready to be transferred to AXI-Stream
      if (data_ready_s4 && !prev_data_ready_s4) begin
        rx_data_out <= rx_data_reg_s4;
        error_flags_out <= {overrun_error_reg_s4, parity_error_reg_s4, framing_error_reg_s4};
        m_axis_tvalid_reg <= 1'b1; // Assert tvalid when new data is available
      end
    end
  end
endmodule
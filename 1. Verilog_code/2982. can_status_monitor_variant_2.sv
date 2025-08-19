//SystemVerilog
module can_status_monitor (
  // Clock and reset
  input  wire        aclk,
  input  wire        aresetn,
  
  // AXI-Stream input interface
  input  wire        s_axis_tvalid,
  output wire        s_axis_tready,
  input  wire [31:0] s_axis_tdata,
  input  wire        s_axis_tlast,
  
  // AXI-Stream output interface
  output wire        m_axis_tvalid,
  input  wire        m_axis_tready,
  output wire [47:0] m_axis_tdata,
  output wire        m_axis_tlast
);

  // Internal signals extracted from input data
  wire tx_active      = s_axis_tdata[0];
  wire rx_active      = s_axis_tdata[1];
  wire error_detected = s_axis_tdata[2];
  wire bus_off        = s_axis_tdata[3];
  wire [7:0] tx_err_count = s_axis_tdata[15:8];
  wire [7:0] rx_err_count = s_axis_tdata[23:16];
  
  // Output registers
  reg [2:0]  node_state;
  reg [15:0] frames_sent;
  reg [15:0] frames_received;
  reg [15:0] errors_detected;
  
  // Output valid register
  reg output_valid;
  
  // Constants
  localparam ERROR_ACTIVE  = 0,
             ERROR_PASSIVE = 1,
             BUS_OFF       = 2;
  
  // Edge detection registers
  reg prev_tx_active, prev_rx_active, prev_error;
  
  // Always ready to receive data
  assign s_axis_tready = 1'b1;
  
  // Main processing logic
  always @(posedge aclk or negedge aresetn) begin
    if (!aresetn) begin
      node_state <= ERROR_ACTIVE;
      frames_sent <= 0;
      frames_received <= 0;
      errors_detected <= 0;
      prev_tx_active <= 0;
      prev_rx_active <= 0;
      prev_error <= 0;
      output_valid <= 0;
    end else begin
      // State transition case statement
      case ({s_axis_tvalid && s_axis_tready, m_axis_tready && output_valid})
        2'b10: begin  // Valid input data received
          prev_tx_active <= tx_active;
          prev_rx_active <= rx_active;
          prev_error <= error_detected;
          
          // Edge detection for frame and error counting
          case ({prev_tx_active, tx_active})
            2'b01: frames_sent <= frames_sent + 1;
            default: frames_sent <= frames_sent;
          endcase
          
          case ({prev_rx_active, rx_active})
            2'b01: frames_received <= frames_received + 1;
            default: frames_received <= frames_received;
          endcase
          
          case ({prev_error, error_detected})
            2'b01: errors_detected <= errors_detected + 1;
            default: errors_detected <= errors_detected;
          endcase
          
          // Node state determination
          case (1'b1)  // Priority encoded case
            bus_off: 
              node_state <= BUS_OFF;
            (tx_err_count > 127) || (rx_err_count > 127): 
              node_state <= ERROR_PASSIVE;
            default: 
              node_state <= ERROR_ACTIVE;
          endcase
          
          output_valid <= 1'b1;
        end
        
        2'b01: begin  // Output data consumed
          output_valid <= 1'b0;
        end
        
        default: begin  // No change in state
          // Maintain current values
        end
      endcase
    end
  end
  
  // Output AXI-Stream signals
  assign m_axis_tvalid = output_valid;
  assign m_axis_tdata = {errors_detected, frames_received, frames_sent, node_state};
  assign m_axis_tlast = 1'b1;  // Each output is a complete transaction

endmodule
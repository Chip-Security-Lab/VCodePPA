//SystemVerilog
module can_bit_destuffer (
  // Clock and reset
  input  wire        clk,
  input  wire        rst_n,
  
  // AXI-Stream Slave interface
  input  wire        s_axis_tvalid,
  output wire        s_axis_tready,
  input  wire        s_axis_tdata,
  input  wire        s_axis_tlast,  // Added tlast signal for input
  
  // AXI-Stream Master interface
  output wire        m_axis_tvalid,
  input  wire        m_axis_tready,
  output wire        m_axis_tdata,
  output wire        m_axis_tlast,
  
  // Control signal
  input  wire        destuffing_active,
  
  // Error output
  output wire        stuff_error
);

  // Internal registers
  reg [2:0]  same_bit_count;
  reg        last_bit;
  reg        data_out_r;
  reg        data_out_valid_r;
  reg        stuff_error_r;
  reg        processing;
  reg        tlast_r;  // Register to store tlast signal
  
  // FSM states
  localparam IDLE = 2'b00;
  localparam PROCESS = 2'b01;
  localparam WAIT_READY = 2'b10;
  
  reg [1:0] state, next_state;
  
  // AXI-Stream interface assignments
  assign s_axis_tready = (state == IDLE) || ((state == PROCESS) && m_axis_tready);
  assign m_axis_tvalid = data_out_valid_r;
  assign m_axis_tdata = data_out_r;
  assign m_axis_tlast = tlast_r;
  assign stuff_error = stuff_error_r;
  
  // State machine - sequential logic
  always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
      state <= IDLE;
    end else begin
      state <= next_state;
    end
  end
  
  // State machine - combinational logic
  always @(*) begin
    next_state = state;
    
    case (state)
      IDLE: begin
        if (s_axis_tvalid && destuffing_active) begin
          next_state = PROCESS;
        end
      end
      
      PROCESS: begin
        if (stuff_error_r) begin
          next_state = IDLE;
        end else if (!m_axis_tready && data_out_valid_r) begin
          next_state = WAIT_READY;
        end else if (!s_axis_tvalid || !destuffing_active) begin
          next_state = IDLE;
        end
      end
      
      WAIT_READY: begin
        if (m_axis_tready) begin
          next_state = IDLE;
        end
      end
      
      default: next_state = IDLE;
    endcase
  end
  
  // Data processing logic
  always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
      same_bit_count <= 3'd0;
      last_bit <= 1'b0;
      data_out_r <= 1'b0;
      data_out_valid_r <= 1'b0;
      stuff_error_r <= 1'b0;
      tlast_r <= 1'b0;
      processing <= 1'b0;
    end else begin
      // Default assignments
      data_out_valid_r <= data_out_valid_r && !m_axis_tready;
      
      if (stuff_error_r && state == IDLE) begin
        stuff_error_r <= 1'b0;
      end
      
      case (state)
        IDLE: begin
          tlast_r <= 1'b0;
        end
        
        PROCESS: begin
          if (s_axis_tvalid && s_axis_tready && destuffing_active) begin
            processing <= 1'b1;
            
            if (same_bit_count == 3'd4 && s_axis_tdata == last_bit) begin
              stuff_error_r <= 1'b1;  // Six consecutive identical bits is an error
              same_bit_count <= 3'd0;
              processing <= 1'b0;
            end else if (same_bit_count == 3'd4) begin
              // This is a stuff bit, don't forward it
              same_bit_count <= 3'd0;
              last_bit <= s_axis_tdata;
              processing <= 1'b0;
            end else begin
              data_out_r <= s_axis_tdata;
              data_out_valid_r <= 1'b1;
              tlast_r <= s_axis_tlast;  // Propagate tlast signal
              
              // Update bit counter
              if (s_axis_tdata == last_bit) begin
                same_bit_count <= same_bit_count + 3'd1;
              end else begin
                same_bit_count <= 3'd1;  // Reset counter to 1 since we're counting this bit
              end
              
              last_bit <= s_axis_tdata;
              processing <= !m_axis_tready;
            end
          end
        end
        
        WAIT_READY: begin
          if (m_axis_tready) begin
            data_out_valid_r <= 1'b0;
            processing <= 1'b0;
          end
        end
      endcase
    end
  end
endmodule
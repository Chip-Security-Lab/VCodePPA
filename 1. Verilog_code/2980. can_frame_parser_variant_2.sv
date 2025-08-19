//SystemVerilog
//IEEE 1364-2005 Verilog
module can_frame_parser(
  // Clock and Reset
  input wire clk,
  input wire rst_n,
  
  // AXI-Stream Input Interface
  input wire [7:0] s_axis_tdata,
  input wire s_axis_tvalid,
  output wire s_axis_tready,
  input wire s_axis_tlast,
  
  // AXI-Stream Output Interface
  output reg [31:0] m_axis_tdata,  // Expanded to contain ID, DLC, RTR, IDE
  output reg m_axis_tvalid,
  input wire m_axis_tready,
  output reg m_axis_tlast
);
  
  // Parameters for state machine
  localparam WAIT_SOF=0, GET_ID=1, GET_CTRL=2, GET_DATA=3, GET_CRC=4, GET_ACK=5, GET_EOF=6;
  
  // Internal registers for CAN frame parsing
  reg [10:0] id;
  reg [7:0] data [0:7];
  reg [3:0] dlc;
  reg rtr, ide, frame_valid;
  
  // State machine and counters
  reg [2:0] state, next_state;
  reg [7:0] bit_count, next_bit_count;
  reg [7:0] byte_count, next_byte_count;
  
  // Pipeline registers
  reg [10:0] id_pipeline;
  reg bit_in_r;
  reg bit_valid_r;
  reg frame_valid_next;
  reg rtr_next;
  
  // AXI-Stream input processing
  reg s_axis_tready_reg;
  assign s_axis_tready = s_axis_tready_reg;
  
  // Bit extraction from AXI-Stream input
  wire bit_in = s_axis_tdata[0];  // Extract LSB from TDATA
  wire bit_valid = s_axis_tvalid && s_axis_tready;
  
  // Output frame assembly
  reg [31:0] output_data;
  reg output_valid;
  reg output_last;
  reg [2:0] output_state;
  
  // First stage combinational logic: state and counter update
  always @(*) begin
    next_state = state;
    next_bit_count = bit_count;
    next_byte_count = byte_count;
    frame_valid_next = frame_valid;
    rtr_next = rtr;
    s_axis_tready_reg = 1'b1;  // Default ready to accept data
    
    if (bit_valid_r) begin
      case (state)
        WAIT_SOF: begin
          if (!bit_in_r) begin 
            next_state = GET_ID; 
            next_bit_count = 0; 
          end
        end
        GET_ID: begin
          if (bit_count < 11) begin
            next_bit_count = bit_count + 1;
          end else begin
            next_state = GET_CTRL;
            rtr_next = bit_in_r;
            next_bit_count = 0;
          end
        end
        // ... existing code ...
      endcase
    end
  end
  
  // Input pipeline register
  always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
      bit_in_r <= 0;
      bit_valid_r <= 0;
    end else begin
      bit_in_r <= bit_in;
      bit_valid_r <= bit_valid;
    end
  end
  
  // State and counter update pipeline register
  always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
      state <= WAIT_SOF;
      bit_count <= 0;
      byte_count <= 0;
      frame_valid <= 0;
      rtr <= 0;
    end else begin
      state <= next_state;
      bit_count <= next_bit_count;
      byte_count <= next_byte_count;
      frame_valid <= frame_valid_next;
      rtr <= rtr_next;
    end
  end
  
  // ID data path pipeline register
  always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
      id <= 0;
      id_pipeline <= 0;
    end else if (bit_valid_r && state == GET_ID && bit_count < 11) begin
      id_pipeline[10-bit_count] <= bit_in_r;
      id <= id_pipeline;
    end
  end
  
  // AXI-Stream output generation
  always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
      m_axis_tdata <= 32'h0;
      m_axis_tvalid <= 1'b0;
      m_axis_tlast <= 1'b0;
      output_state <= 3'b0;
    end else begin
      case (output_state)
        3'b000: begin
          if (frame_valid) begin
            // Pack ID, DLC, RTR, IDE into tdata
            m_axis_tdata <= {id, dlc, rtr, ide, 15'b0};
            m_axis_tvalid <= 1'b1;
            m_axis_tlast <= 1'b0;
            output_state <= 3'b001;
          end else begin
            m_axis_tvalid <= 1'b0;
          end
        end
        3'b001: begin
          if (m_axis_tready) begin
            // First data bytes
            m_axis_tdata <= {data[0], data[1], data[2], data[3]};
            m_axis_tvalid <= 1'b1;
            m_axis_tlast <= (dlc <= 4);
            output_state <= (dlc <= 4) ? 3'b000 : 3'b010;
          end
        end
        3'b010: begin
          if (m_axis_tready) begin
            // Remaining data bytes
            m_axis_tdata <= {data[4], data[5], data[6], data[7]};
            m_axis_tvalid <= 1'b1;
            m_axis_tlast <= 1'b1;
            output_state <= 3'b000;
          end
        end
        default: output_state <= 3'b000;
      endcase
    end
  end
endmodule
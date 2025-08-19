//SystemVerilog
module can_buffer_controller #(
  parameter BUFFER_DEPTH = 8
)(
  input wire clk, rst_n,
  input wire rx_done,
  input wire [10:0] rx_id,
  input wire [7:0] rx_data [0:7],
  input wire [3:0] rx_dlc,
  input wire tx_request, tx_done,
  output reg [10:0] tx_id,
  output reg [7:0] tx_data [0:7],
  output reg [3:0] tx_dlc,
  output reg buffer_full, buffer_empty,
  output reg [3:0] buffer_level
);
  // Buffer storage
  reg [10:0] id_buffer [0:BUFFER_DEPTH-1];
  reg [7:0] data_buffer [0:BUFFER_DEPTH-1][0:7];
  reg [3:0] dlc_buffer [0:BUFFER_DEPTH-1];
  
  // Pipeline stage pointers and control signals
  reg [$clog2(BUFFER_DEPTH):0] rd_ptr_stage1, rd_ptr_stage2;
  reg [$clog2(BUFFER_DEPTH):0] wr_ptr_stage1, wr_ptr_stage2;
  
  // Pre-calculated buffer status for lower logic depth
  reg buffer_full_stage1, buffer_empty_stage1;
  reg [3:0] buffer_level_stage1, buffer_level_stage2;
  
  // Pipeline control signals
  reg rx_done_stage1, rx_done_stage2;
  reg tx_request_stage1, tx_request_stage2;
  reg tx_done_stage1, tx_done_stage2;
  
  // Temporary storage for data being processed
  reg [10:0] rx_id_stage1, rx_id_stage2;
  reg [7:0] rx_data_stage1 [0:7], rx_data_stage2 [0:7];
  reg [3:0] rx_dlc_stage1, rx_dlc_stage2;
  reg [10:0] tx_id_stage1;
  reg [7:0] tx_data_stage1 [0:7];
  reg [3:0] tx_dlc_stage1;
  
  // Early computed write/read enable signals to reduce logic depth
  reg write_en, read_en;
  reg [$clog2(BUFFER_DEPTH):0] next_wr_ptr, next_rd_ptr;
  reg [3:0] next_buffer_level;
  
  // Pre-compute control signals for next cycle to reduce critical path
  always @(*) begin
    // Pre-calculate write enable condition
    write_en = rx_done_stage1 && !buffer_full_stage1;
    
    // Pre-calculate read enable condition
    read_en = tx_request_stage1 && !buffer_empty_stage1 && tx_done_stage1;
    
    // Pre-calculate next pointer values
    next_wr_ptr = write_en ? (wr_ptr_stage1 + 1'b1) : wr_ptr_stage1;
    next_rd_ptr = read_en ? (rd_ptr_stage1 + 1'b1) : rd_ptr_stage1;
    
    // Pre-calculate buffer level changes
    case ({write_en, read_en})
      2'b00: next_buffer_level = buffer_level_stage1;
      2'b01: next_buffer_level = buffer_level_stage1 - 1'b1;
      2'b10: next_buffer_level = buffer_level_stage1 + 1'b1;
      2'b11: next_buffer_level = buffer_level_stage1;
    endcase
  end
  
  // Stage 1 - Input capture and state evaluation
  always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
      // Reset stage 1 registers
      rd_ptr_stage1 <= 0;
      wr_ptr_stage1 <= 0;
      buffer_full_stage1 <= 0;
      buffer_empty_stage1 <= 1;
      buffer_level_stage1 <= 0;
      rx_done_stage1 <= 0;
      tx_request_stage1 <= 0;
      tx_done_stage1 <= 0;
      
      // Reset input capture registers
      rx_id_stage1 <= 0;
      rx_dlc_stage1 <= 0;
      for (int i = 0; i < 8; i++) begin
        rx_data_stage1[i] <= 0;
      end
    end else begin
      // Capture inputs
      rx_done_stage1 <= rx_done;
      tx_request_stage1 <= tx_request;
      tx_done_stage1 <= tx_done;
      rx_id_stage1 <= rx_id;
      rx_dlc_stage1 <= rx_dlc;
      for (int i = 0; i < 8; i++) begin
        rx_data_stage1[i] <= rx_data[i];
      end
      
      // Simplified buffer status calculations
      buffer_empty_stage1 <= (wr_ptr_stage2 == rd_ptr_stage2);
      buffer_full_stage1 <= (buffer_level_stage2 == BUFFER_DEPTH);
      buffer_level_stage1 <= buffer_level_stage2;
    end
  end
  
  // Stage 2 - Processing logic and pointer updates
  always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
      // Reset stage 2 registers
      rd_ptr_stage2 <= 0;
      wr_ptr_stage2 <= 0;
      buffer_level_stage2 <= 0;
      rx_done_stage2 <= 0;
      tx_request_stage2 <= 0;
      tx_done_stage2 <= 0;
      
      // Reset processing registers
      rx_id_stage2 <= 0;
      rx_dlc_stage2 <= 0;
      for (int i = 0; i < 8; i++) begin
        rx_data_stage2[i] <= 0;
      end
    end else begin
      // Forward control signals
      rx_done_stage2 <= rx_done_stage1;
      tx_request_stage2 <= tx_request_stage1;
      tx_done_stage2 <= tx_done_stage1;
      
      // Forward data
      rx_id_stage2 <= rx_id_stage1;
      rx_dlc_stage2 <= rx_dlc_stage1;
      for (int i = 0; i < 8; i++) begin
        rx_data_stage2[i] <= rx_data_stage1[i];
      end
      
      // Use pre-computed values to update pointers and buffer
      wr_ptr_stage2 <= next_wr_ptr;
      rd_ptr_stage2 <= next_rd_ptr;
      buffer_level_stage2 <= next_buffer_level;
      
      // Process write operation
      if (write_en) begin
        id_buffer[wr_ptr_stage1] <= rx_id_stage1;
        dlc_buffer[wr_ptr_stage1] <= rx_dlc_stage1;
        for (int i = 0; i < 8; i++) begin
          data_buffer[wr_ptr_stage1][i] <= rx_data_stage1[i];
        end
      end
      
      // Process read operation (split complex condition)
      if (read_en) begin
        tx_id_stage1 <= id_buffer[rd_ptr_stage1];
        tx_dlc_stage1 <= dlc_buffer[rd_ptr_stage1];
        for (int i = 0; i < 8; i++) begin
          tx_data_stage1[i] <= data_buffer[rd_ptr_stage1][i];
        end
      end else begin
        // Preserve previous values if no read operation
        tx_id_stage1 <= tx_id;
        tx_dlc_stage1 <= tx_dlc;
        for (int i = 0; i < 8; i++) begin
          tx_data_stage1[i] <= tx_data[i];
        end
      end
    end
  end
  
  // Stage 3 - Output registers
  always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
      // Reset output registers
      tx_id <= 0;
      tx_dlc <= 0;
      for (int i = 0; i < 8; i++) begin
        tx_data[i] <= 0;
      end
      buffer_full <= 0;
      buffer_empty <= 1;
      buffer_level <= 0;
      
      // Reset pointers for first stage
      rd_ptr_stage1 <= 0;
      wr_ptr_stage1 <= 0;
    end else begin
      // Update output registers
      tx_id <= tx_id_stage1;
      tx_dlc <= tx_dlc_stage1;
      for (int i = 0; i < 8; i++) begin
        tx_data[i] <= tx_data_stage1[i];
      end
      
      // Direct buffer status outputs
      buffer_full <= buffer_full_stage1;
      buffer_empty <= buffer_empty_stage1;
      buffer_level <= buffer_level_stage2;
      
      // Forward pointers to first stage
      rd_ptr_stage1 <= rd_ptr_stage2;
      wr_ptr_stage1 <= wr_ptr_stage2;
    end
  end
endmodule
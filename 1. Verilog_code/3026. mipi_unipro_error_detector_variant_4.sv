//SystemVerilog
module mipi_unipro_error_detector (
  input wire clk, reset_n,
  input wire [31:0] frame_data,
  input wire frame_valid, frame_start, frame_end,
  output reg error_detected,
  output reg [3:0] error_type
);

  localparam NO_ERROR = 4'd0, CRC_ERROR = 4'd1, LEN_ERROR = 4'd2;
  localparam SEQ_ERROR = 4'd3, TIMEOUT_ERROR = 4'd4;
  
  // Pipeline stage 1 registers
  reg [31:0] frame_data_stage1;
  reg frame_valid_stage1, frame_start_stage1, frame_end_stage1;
  reg [2:0] state_stage1;
  reg [7:0] seq_num_stage1;
  reg [15:0] crc_stage1;
  reg [1:0] frame_state_stage1;
  
  // Pipeline stage 2 registers  
  reg [31:0] frame_data_stage2;
  reg frame_valid_stage2, frame_start_stage2, frame_end_stage2;
  reg [2:0] state_stage2;
  reg [7:0] seq_num_stage2;
  reg [15:0] crc_stage2;
  reg [1:0] frame_state_stage2;
  
  // Pipeline stage 3 registers
  reg [31:0] frame_data_stage3;
  reg frame_valid_stage3, frame_start_stage3, frame_end_stage3;
  reg [2:0] state_stage3;
  reg [7:0] seq_num_stage3;
  reg [15:0] crc_stage3;
  reg [1:0] frame_state_stage3;
  
  // Final stage registers
  reg [7:0] prev_seq_num;
  reg [15:0] expected_crc;
  
  // Stage 1: Input sampling and initial processing
  always @(posedge clk or negedge reset_n) begin
    if (!reset_n) begin
      frame_data_stage1 <= 32'd0;
      frame_valid_stage1 <= 1'b0;
      frame_start_stage1 <= 1'b0;
      frame_end_stage1 <= 1'b0;
      state_stage1 <= 3'd0;
      seq_num_stage1 <= 8'd0;
      crc_stage1 <= 16'hFFFF;
      frame_state_stage1 <= 2'd0;
    end else begin
      frame_data_stage1 <= frame_data;
      frame_valid_stage1 <= frame_valid;
      frame_start_stage1 <= frame_start;
      frame_end_stage1 <= frame_end;
      
      if (frame_valid) begin
        if (frame_start) begin
          state_stage1 <= 3'd1;
          seq_num_stage1 <= frame_data[7:0];
          crc_stage1 <= 16'hFFFF;
          frame_state_stage1 <= 2'd1;
        end else begin
          state_stage1 <= state_stage1;
          seq_num_stage1 <= seq_num_stage1;
          crc_stage1 <= crc_stage1;
          frame_state_stage1 <= frame_state_stage1;
        end
      end
    end
  end
  
  // Stage 2: CRC calculation
  always @(posedge clk or negedge reset_n) begin
    if (!reset_n) begin
      frame_data_stage2 <= 32'd0;
      frame_valid_stage2 <= 1'b0;
      frame_start_stage2 <= 1'b0;
      frame_end_stage2 <= 1'b0;
      state_stage2 <= 3'd0;
      seq_num_stage2 <= 8'd0;
      crc_stage2 <= 16'hFFFF;
      frame_state_stage2 <= 2'd0;
    end else begin
      frame_data_stage2 <= frame_data_stage1;
      frame_valid_stage2 <= frame_valid_stage1;
      frame_start_stage2 <= frame_start_stage1;
      frame_end_stage2 <= frame_end_stage1;
      state_stage2 <= state_stage1;
      seq_num_stage2 <= seq_num_stage1;
      frame_state_stage2 <= frame_state_stage1;
      
      if (frame_valid_stage1 && frame_state_stage1 == 2'd1 && !frame_end_stage1) begin
        crc_stage2 <= crc_stage1 ^ {frame_data_stage1[15:0], 16'h0000};
      end else begin
        crc_stage2 <= crc_stage1;
      end
    end
  end
  
  // Stage 3: Error detection preparation
  always @(posedge clk or negedge reset_n) begin
    if (!reset_n) begin
      frame_data_stage3 <= 32'd0;
      frame_valid_stage3 <= 1'b0;
      frame_start_stage3 <= 1'b0;
      frame_end_stage3 <= 1'b0;
      state_stage3 <= 3'd0;
      seq_num_stage3 <= 8'd0;
      crc_stage3 <= 16'hFFFF;
      frame_state_stage3 <= 2'd0;
    end else begin
      frame_data_stage3 <= frame_data_stage2;
      frame_valid_stage3 <= frame_valid_stage2;
      frame_start_stage3 <= frame_start_stage2;
      frame_end_stage3 <= frame_end_stage2;
      state_stage3 <= state_stage2;
      seq_num_stage3 <= seq_num_stage2;
      crc_stage3 <= crc_stage2;
      frame_state_stage3 <= frame_state_stage2;
    end
  end
  
  // Final stage: Error detection and output
  always @(posedge clk or negedge reset_n) begin
    if (!reset_n) begin
      error_detected <= 1'b0;
      error_type <= NO_ERROR;
      prev_seq_num <= 8'd0;
      expected_crc <= 16'd0;
    end else begin
      if (frame_valid_stage3 && frame_state_stage3 == 2'd1 && frame_end_stage3) begin
        expected_crc <= frame_data_stage3[31:16];
        
        if (crc_stage3 != frame_data_stage3[31:16]) begin
          error_detected <= 1'b1;
          error_type <= CRC_ERROR;
        end else if ((prev_seq_num + 1'b1) != seq_num_stage3) begin
          error_detected <= 1'b1;
          error_type <= SEQ_ERROR;
        end else begin
          error_detected <= 1'b0;
          error_type <= NO_ERROR;
        end
        
        prev_seq_num <= seq_num_stage3;
      end else begin
        error_detected <= 1'b0;
        error_type <= NO_ERROR;
      end
    end
  end

endmodule
//SystemVerilog
module mipi_unipro_error_detector (
  input wire clk,
  input wire reset_n,
  input wire [31:0] frame_data,
  input wire frame_valid,
  input wire frame_start,
  input wire frame_end,
  output reg error_detected,
  output reg [3:0] error_type,
  output reg data_ready,
  input wire data_valid
);

  localparam NO_ERROR = 4'd0, CRC_ERROR = 4'd1, LEN_ERROR = 4'd2;
  localparam SEQ_ERROR = 4'd3, TIMEOUT_ERROR = 4'd4;
  
  reg [2:0] state;
  reg [15:0] crc, expected_crc;
  reg [7:0] seq_num, prev_seq_num;
  reg [31:0] data_reg, data_reg_buf;
  reg frame_valid_reg, frame_valid_buf;
  reg frame_start_reg, frame_start_buf;
  reg frame_end_reg, frame_end_buf;
  reg data_ready_buf;
  reg [3:0] error_type_buf;
  reg error_detected_buf;
  
  always @(posedge clk or negedge reset_n) begin
    if (!reset_n) begin
      state <= 3'd0;
      error_detected <= 1'b0;
      error_type <= NO_ERROR;
      prev_seq_num <= 8'd0;
      data_ready <= 1'b0;
      data_reg <= 32'd0;
      data_reg_buf <= 32'd0;
      frame_valid_reg <= 1'b0;
      frame_valid_buf <= 1'b0;
      frame_start_reg <= 1'b0;
      frame_start_buf <= 1'b0;
      frame_end_reg <= 1'b0;
      frame_end_buf <= 1'b0;
      data_ready_buf <= 1'b0;
      error_type_buf <= NO_ERROR;
      error_detected_buf <= 1'b0;
    end else begin
      data_ready_buf <= 1'b1;
      data_ready <= data_ready_buf;
      
      if (data_valid && data_ready_buf) begin
        data_reg_buf <= frame_data;
        frame_valid_buf <= frame_valid;
        frame_start_buf <= frame_start;
        frame_end_buf <= frame_end;
        
        data_reg <= data_reg_buf;
        frame_valid_reg <= frame_valid_buf;
        frame_start_reg <= frame_start_buf;
        frame_end_reg <= frame_end_buf;
        
        if (frame_valid_reg) begin
          if (frame_start_reg) begin
            state <= 3'd1;
            seq_num <= data_reg[7:0];
            crc <= 16'hFFFF;
          end else if (frame_end_reg) begin
            expected_crc <= data_reg[31:16];
            if (crc != expected_crc) begin
              error_detected_buf <= 1'b1;
              error_type_buf <= CRC_ERROR;
            end else if ((prev_seq_num + 1'b1) != seq_num) begin
              error_detected_buf <= 1'b1;
              error_type_buf <= SEQ_ERROR;
            end
            prev_seq_num <= seq_num;
          end else begin
            crc <= crc ^ {data_reg[15:0], 16'h0000};
          end
        end
        
        error_detected <= error_detected_buf;
        error_type <= error_type_buf;
      end
    end
  end
endmodule
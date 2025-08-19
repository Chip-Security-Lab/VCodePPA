module mipi_unipro_error_detector (
  input wire clk, reset_n,
  input wire [31:0] frame_data,
  input wire frame_valid, frame_start, frame_end,
  output reg error_detected,
  output reg [3:0] error_type
);
  localparam NO_ERROR = 4'd0, CRC_ERROR = 4'd1, LEN_ERROR = 4'd2;
  localparam SEQ_ERROR = 4'd3, TIMEOUT_ERROR = 4'd4;
  
  reg [2:0] state;
  reg [15:0] crc, expected_crc;
  reg [7:0] seq_num, prev_seq_num;
  
  always @(posedge clk or negedge reset_n) begin
    if (!reset_n) begin
      state <= 3'd0;
      error_detected <= 1'b0;
      error_type <= NO_ERROR;
      prev_seq_num <= 8'd0;
    end else if (frame_valid) begin
      if (frame_start) begin
        state <= 3'd1;
        seq_num <= frame_data[7:0];
        crc <= 16'hFFFF;
      end else if (frame_end) begin
        expected_crc <= frame_data[31:16];
        if (crc != expected_crc) begin
          error_detected <= 1'b1;
          error_type <= CRC_ERROR;
        end else if ((prev_seq_num + 1'b1) != seq_num) begin
          error_detected <= 1'b1;
          error_type <= SEQ_ERROR;
        end
        prev_seq_num <= seq_num;
      end else begin
        // Update CRC calculation
        crc <= crc ^ {frame_data[15:0], 16'h0000};
      end
    end
  end
endmodule
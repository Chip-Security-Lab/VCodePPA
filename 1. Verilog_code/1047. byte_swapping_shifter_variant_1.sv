//SystemVerilog
module byte_swapping_shifter (
  input wire clk,
  input wire rst_n,
  input wire [31:0] data_in,
  input wire [1:0] swap_mode, // 00=none, 01=swap bytes, 10=swap words, 11=reverse
  output reg [31:0] data_out
);

  // Stage 1: Input register
  reg [31:0] data_in_stage1;
  reg [1:0]  swap_mode_stage1;
  always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
      data_in_stage1 <= 32'd0;
      swap_mode_stage1 <= 2'b00;
    end else begin
      data_in_stage1 <= data_in;
      swap_mode_stage1 <= swap_mode;
    end
  end

  // Stage 2: Swap bytes and swap words calculation
  reg [31:0] swap_bytes_stage2;
  reg [31:0] swap_words_stage2;
  reg [31:0] data_in_stage2;
  reg [1:0]  swap_mode_stage2;
  always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
      swap_bytes_stage2 <= 32'd0;
      swap_words_stage2 <= 32'd0;
      data_in_stage2 <= 32'd0;
      swap_mode_stage2 <= 2'b00;
    end else begin
      swap_bytes_stage2 <= {data_in_stage1[7:0], data_in_stage1[15:8], data_in_stage1[23:16], data_in_stage1[31:24]};
      swap_words_stage2 <= {data_in_stage1[15:0], data_in_stage1[31:16]};
      data_in_stage2 <= data_in_stage1;
      swap_mode_stage2 <= swap_mode_stage1;
    end
  end

  // Stage 3: Reverse bits - first half (bits 31:16)
  reg [15:0] reverse_upper_stage3;
  reg [15:0] reverse_lower_stage3;
  reg [31:0] data_in_stage3;
  reg [1:0]  swap_mode_stage3;
  reg [31:0] swap_bytes_stage3;
  reg [31:0] swap_words_stage3;
  always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
      reverse_upper_stage3 <= 16'd0;
      reverse_lower_stage3 <= 16'd0;
      data_in_stage3 <= 32'd0;
      swap_mode_stage3 <= 2'b00;
      swap_bytes_stage3 <= 32'd0;
      swap_words_stage3 <= 32'd0;
    end else begin
      reverse_upper_stage3 <= { data_in_stage2[0],  data_in_stage2[1],  data_in_stage2[2],  data_in_stage2[3],
                                data_in_stage2[4],  data_in_stage2[5],  data_in_stage2[6],  data_in_stage2[7],
                                data_in_stage2[8],  data_in_stage2[9],  data_in_stage2[10], data_in_stage2[11],
                                data_in_stage2[12], data_in_stage2[13], data_in_stage2[14], data_in_stage2[15] };
      reverse_lower_stage3 <= { data_in_stage2[16], data_in_stage2[17], data_in_stage2[18], data_in_stage2[19],
                                data_in_stage2[20], data_in_stage2[21], data_in_stage2[22], data_in_stage2[23],
                                data_in_stage2[24], data_in_stage2[25], data_in_stage2[26], data_in_stage2[27],
                                data_in_stage2[28], data_in_stage2[29], data_in_stage2[30], data_in_stage2[31] };
      data_in_stage3 <= data_in_stage2;
      swap_mode_stage3 <= swap_mode_stage2;
      swap_bytes_stage3 <= swap_bytes_stage2;
      swap_words_stage3 <= swap_words_stage2;
    end
  end

  // Stage 4: Reverse bits - second half (bits 15:0)
  reg [31:0] reverse_bits_stage4;
  reg [31:0] data_in_stage4;
  reg [1:0]  swap_mode_stage4;
  reg [31:0] swap_bytes_stage4;
  reg [31:0] swap_words_stage4;
  always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
      reverse_bits_stage4 <= 32'd0;
      data_in_stage4 <= 32'd0;
      swap_mode_stage4 <= 2'b00;
      swap_bytes_stage4 <= 32'd0;
      swap_words_stage4 <= 32'd0;
    end else begin
      // Reverse 32 bits: concatenate reversed upper and lower
      reverse_bits_stage4 <= { reverse_upper_stage3, reverse_lower_stage3 };
      data_in_stage4 <= data_in_stage3;
      swap_mode_stage4 <= swap_mode_stage3;
      swap_bytes_stage4 <= swap_bytes_stage3;
      swap_words_stage4 <= swap_words_stage3;
    end
  end

  // Stage 5: Output selection
  always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
      data_out <= 32'd0;
    end else begin
      case (swap_mode_stage4)
        2'b00: data_out <= data_in_stage4;
        2'b01: data_out <= swap_bytes_stage4;
        2'b10: data_out <= swap_words_stage4;
        2'b11: data_out <= reverse_bits_stage4;
        default: data_out <= data_in_stage4;
      endcase
    end
  end

endmodule
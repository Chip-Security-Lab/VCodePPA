//SystemVerilog
module conditional_shift_register #(parameter WIDTH=8) (
  input clk,
  input reset,
  input [WIDTH-1:0] parallel_in,
  input shift_in_bit,
  input [1:0] mode, // 00=hold, 01=load, 10=shift right, 11=shift left
  input condition,  // Only perform operation if condition is true
  output reg [WIDTH-1:0] parallel_out,
  output shift_out_bit
);

  // Buffer for high fanout 'mode' signal (stage 1)
  reg [1:0] mode_buf1;
  // Buffer for high fanout 'mode' signal (stage 2)
  reg [1:0] mode_buf2;

  // Buffer for high fanout 'parallel_out' signal (stage 1)
  reg [WIDTH-1:0] parallel_out_buf1;
  // Buffer for high fanout 'parallel_out' signal (stage 2)
  reg [WIDTH-1:0] parallel_out_buf2;

  // Buffer 'mode' signal to reduce fanout tree
  always @(posedge clk or posedge reset) begin
    if (reset) begin
      mode_buf1 <= 2'b00;
      mode_buf2 <= 2'b00;
    end else begin
      mode_buf1 <= mode;
      mode_buf2 <= mode_buf1;
    end
  end

  // Main shift register logic with buffered 'mode' and output buffering
  always @(posedge clk or posedge reset) begin
    if (reset) begin
      parallel_out <= {WIDTH{1'b0}};
      parallel_out_buf1 <= {WIDTH{1'b0}};
      parallel_out_buf2 <= {WIDTH{1'b0}};
    end else if (condition) begin
      if (mode_buf2 == 2'b01) begin
        parallel_out <= parallel_in;
      end else if (mode_buf2 == 2'b10) begin
        parallel_out <= {shift_in_bit, parallel_out[WIDTH-1:1]};
      end else if (mode_buf2 == 2'b11) begin
        parallel_out <= {parallel_out[WIDTH-2:0], shift_in_bit};
      end else begin
        parallel_out <= parallel_out; // Hold current value
      end
      // Buffering parallel_out for fanout reduction
      parallel_out_buf1 <= parallel_out;
      parallel_out_buf2 <= parallel_out_buf1;
    end else begin
      // Maintain output buffers when not active to avoid glitches
      parallel_out_buf1 <= parallel_out;
      parallel_out_buf2 <= parallel_out_buf1;
    end
  end

  // Use buffered signals for shift_out_bit calculation
  assign shift_out_bit = (mode_buf2 == 2'b10) ? parallel_out_buf2[0] : parallel_out_buf2[WIDTH-1];

endmodule
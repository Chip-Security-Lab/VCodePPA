//SystemVerilog
module conditional_shift_register #(parameter WIDTH=8) (
  input wire clk,
  input wire reset,
  input wire [WIDTH-1:0] parallel_in,
  input wire shift_in_bit,
  input wire [1:0] mode, // 00=hold, 01=load, 10=shift right, 11=shift left
  input wire condition,   // Only perform operation if condition is true
  output reg [WIDTH-1:0] parallel_out,
  output wire shift_out_bit
);

  // Input retiming registers
  reg [WIDTH-1:0] retimed_parallel_in;
  reg retimed_shift_in_bit;
  reg [1:0] retimed_mode;
  reg retimed_condition;

  always @(posedge clk or posedge reset) begin
    if (reset) begin
      retimed_parallel_in <= {WIDTH{1'b0}};
      retimed_shift_in_bit <= 1'b0;
      retimed_mode <= 2'b00;
      retimed_condition <= 1'b0;
    end else begin
      retimed_parallel_in <= parallel_in;
      retimed_shift_in_bit <= shift_in_bit;
      retimed_mode <= mode;
      retimed_condition <= condition;
    end
  end

  // Next state logic
  reg [WIDTH-1:0] parallel_out_next;
  wire mode_is_load   = (retimed_mode == 2'b01);
  wire mode_is_shr    = (retimed_mode == 2'b10);
  wire mode_is_shl    = (retimed_mode == 2'b11);
  wire mode_is_hold   = (retimed_mode == 2'b00);

  always @(*) begin
    // Default: hold
    parallel_out_next = parallel_out;
    if (retimed_condition) begin
      // Priority: load > shift right > shift left > hold
      if (mode_is_load) begin
        parallel_out_next = retimed_parallel_in;
      end else if (mode_is_shr) begin
        parallel_out_next = {retimed_shift_in_bit, parallel_out[WIDTH-1:1]};
      end else if (mode_is_shl) begin
        parallel_out_next = {parallel_out[WIDTH-2:0], retimed_shift_in_bit};
      end
      // else hold (already assigned)
    end
  end

  always @(posedge clk or posedge reset) begin
    if (reset)
      parallel_out <= {WIDTH{1'b0}};
    else
      parallel_out <= parallel_out_next;
  end

  // Efficient shift_out_bit logic
  assign shift_out_bit = mode_is_shr ? parallel_out[0] : parallel_out[WIDTH-1];

endmodule
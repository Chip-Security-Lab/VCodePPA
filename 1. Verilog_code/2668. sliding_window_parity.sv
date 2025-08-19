module sliding_window_parity(
  input clk, rst_n,
  input data_bit,
  input [2:0] window_size,
  output reg window_parity
);
  reg [7:0] shift_reg;
  integer i;
  
  always @(posedge clk) begin
    if (!rst_n) begin
      shift_reg <= 8'h00;
      window_parity <= 1'b0;
    end else begin
      shift_reg <= {shift_reg[6:0], data_bit};
      
      window_parity = 1'b0;
      for (i = 0; i < 8; i = i + 1)
        if (i < window_size)
          window_parity = window_parity ^ shift_reg[i];
    end
  end
endmodule
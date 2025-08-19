//SystemVerilog
module sliding_window_parity(
  input clk, rst_n,
  input data_bit,
  input [2:0] window_size,
  input req,           // Request signal (replaces valid)
  output reg ack,      // Acknowledge signal (replaces ready)
  output reg window_parity
);
  reg [7:0] shift_reg;
  reg processing;
  integer i;
  
  always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
      shift_reg <= 8'h00;
      window_parity <= 1'b0;
      ack <= 1'b0;
      processing <= 1'b0;
    end else begin
      // Default value for ack
      ack <= 1'b0;
      
      if (req && !processing) begin
        // New data request received
        shift_reg <= {shift_reg[6:0], data_bit};
        processing <= 1'b1;
        
        // Calculate parity
        window_parity <= 1'b0;
        for (i = 0; i < 8; i = i + 1)
          if (i < window_size)
            window_parity <= window_parity ^ (i == 0 ? data_bit : shift_reg[i-1]);
      end
      
      if (processing) begin
        // Processing complete, send acknowledge
        ack <= 1'b1;
        processing <= 1'b0;
      end
    end
  end
endmodule
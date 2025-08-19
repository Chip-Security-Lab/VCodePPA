module reset_controller(
  input clk, master_rst_n, power_stable,
  output reg core_rst_n, periph_rst_n, io_rst_n
);
  reg [1:0] rst_state;
  
  always @(posedge clk or negedge master_rst_n) begin
    if (!master_rst_n) begin
      rst_state <= 2'b00;
      core_rst_n <= 1'b0;
      periph_rst_n <= 1'b0;
      io_rst_n <= 1'b0;
    end else if (power_stable) begin
      case (rst_state)
        2'b00: begin core_rst_n <= 1'b1; rst_state <= 2'b01; end
        2'b01: begin periph_rst_n <= 1'b1; rst_state <= 2'b10; end
        2'b10: begin io_rst_n <= 1'b1; rst_state <= 2'b11; end
        2'b11: rst_state <= 2'b11;
      endcase
    end
  end
endmodule
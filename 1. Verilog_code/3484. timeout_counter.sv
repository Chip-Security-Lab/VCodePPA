module timeout_counter #(parameter TIMEOUT = 100)(
  input clk, manual_rst, enable,
  output reg timeout_flag
);
  reg [$clog2(TIMEOUT):0] counter;
  
  always @(posedge clk) begin
    if (manual_rst) begin
      counter <= 0;
      timeout_flag <= 0;
    end else if (enable) begin
      if (counter >= TIMEOUT - 1) begin
        counter <= 0;
        timeout_flag <= 1;
      end else begin
        counter <= counter + 1;
        timeout_flag <= 0;
      end
    end
  end
endmodule
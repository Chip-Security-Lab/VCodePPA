//SystemVerilog
module dual_reset_counter #(parameter WIDTH = 8)(
  input clk, sync_rst, async_rst_n, enable,
  output reg [WIDTH-1:0] count
);
  // Buffered reset and enable signals to reduce fanout
  reg sync_rst_buf, enable_buf;
  
  // Combined always block for both buffering and counter logic
  // with the same trigger condition (posedge clk or negedge async_rst_n)
  always @(posedge clk or negedge async_rst_n) begin
    if (!async_rst_n) begin
      // Reset all registers in one block
      sync_rst_buf <= 1'b0;
      enable_buf <= 1'b0;
      count <= {WIDTH{1'b0}};
    end else begin
      // Buffer control signals first
      sync_rst_buf <= sync_rst;
      enable_buf <= enable;
      
      // Then handle counter logic
      if (sync_rst_buf)
        count <= {WIDTH{1'b0}};
      else if (enable_buf)
        count <= count + 1'b1;
    end
  end
endmodule
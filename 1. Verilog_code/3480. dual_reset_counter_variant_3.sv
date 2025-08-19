//SystemVerilog
module dual_reset_counter #(parameter WIDTH = 8)(
  input clk, sync_rst, async_rst_n, enable,
  output reg [WIDTH-1:0] count
);
  // Internal signal for retimed design
  reg enable_reg;
  
  // Combined always block for signals with same trigger condition
  always @(posedge clk or negedge async_rst_n) begin
    if (!async_rst_n) begin
      enable_reg <= 1'b0;
      count <= {WIDTH{1'b0}};
    end
    else begin
      enable_reg <= enable;
      
      if (sync_rst)
        count <= {WIDTH{1'b0}};
      else if (enable_reg)
        count <= count + 1'b1;
    end
  end
endmodule
//SystemVerilog
module sync_reset_counter #(parameter WIDTH = 8)(
  input clk, rst_n, enable,
  output reg [WIDTH-1:0] count
);
  
  always @(posedge clk) begin
    case ({rst_n, enable})
      2'b00: count <= {WIDTH{1'b0}}; // 复位有效，使能无效
      2'b01: count <= {WIDTH{1'b0}}; // 复位有效，使能有效（复位优先）
      2'b10: count <= count;         // 复位无效，使能无效
      2'b11: count <= count + 1'b1;  // 复位无效，使能有效
    endcase
  end
  
endmodule
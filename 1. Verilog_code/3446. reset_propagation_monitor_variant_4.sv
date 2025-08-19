//SystemVerilog
module reset_propagation_monitor (
  input wire clk,
  input wire reset_src,
  input wire [3:0] reset_dst,
  output reg propagation_error
);
  reg reset_src_d;
  reg [7:0] timeout;
  reg checking;
  
  // 定义状态编码
  reg [1:0] state;
  localparam IDLE = 2'b00;
  localparam RESET_DETECTED = 2'b01;
  localparam CHECKING = 2'b10;
  
  always @(posedge clk) begin
    reset_src_d <= reset_src;
    
    case (state)
      IDLE: begin
        if (reset_src && !reset_src_d) begin
          state <= RESET_DETECTED;
          checking <= 1'b1;
          timeout <= 8'd0;
          propagation_error <= 1'b0;
        end
      end
      
      RESET_DETECTED, CHECKING: begin
        timeout <= timeout + 8'd1;
        
        if (&reset_dst) begin
          checking <= 1'b0;
          state <= IDLE;
        end
        else if (timeout == 8'hFF) begin
          propagation_error <= 1'b1;
          checking <= 1'b0;
          state <= IDLE;
        end
      end
      
      default: state <= IDLE;
    endcase
  end
endmodule
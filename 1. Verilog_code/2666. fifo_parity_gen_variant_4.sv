//SystemVerilog
module fifo_parity_gen(
  input clk, rst_n, wr_en, rd_en,
  input [7:0] data_in,
  output reg fifo_parity,
  output reg [3:0] fifo_count
);
  reg parity_accumulator;
  wire fifo_empty;
  wire [1:0] op_mode;
  
  assign fifo_empty = ~|fifo_count;
  assign op_mode = {wr_en, rd_en};
  
  always @(posedge clk) begin
    if (!rst_n) begin
      fifo_count <= 4'b0000;
      parity_accumulator <= 1'b0;
      fifo_parity <= 1'b0;
    end else begin
      case (op_mode)
        2'b10: begin // Write operation
          fifo_count <= fifo_count + 1'b1;
          parity_accumulator <= parity_accumulator ^ (^data_in);
        end
        2'b01: begin // Read operation
          if (!fifo_empty) begin
            fifo_count <= fifo_count - 1'b1;
            fifo_parity <= parity_accumulator;
          end
        end
        default: begin
          fifo_count <= fifo_count;
          parity_accumulator <= parity_accumulator;
          fifo_parity <= fifo_parity;
        end
      endcase
    end
  end
endmodule
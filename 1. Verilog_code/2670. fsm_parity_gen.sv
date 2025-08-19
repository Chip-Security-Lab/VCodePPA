module fsm_parity_gen(
  input clk, rst, start,
  input [15:0] data_in,
  output reg valid, 
  output reg parity_bit
);
  localparam IDLE = 2'b00, COMPUTE = 2'b01, DONE = 2'b10;
  reg [1:0] state, next_state;
  reg [3:0] bit_pos;
  
  always @(posedge clk) begin
    if (rst) begin
      state <= IDLE;
      bit_pos <= 4'd0;
      parity_bit <= 1'b0;
      valid <= 1'b0;
    end else begin
      case (state)
        IDLE: begin
          if (start) begin
            state <= COMPUTE;
            bit_pos <= 4'd0;
            parity_bit <= 1'b0;
            valid <= 1'b0;
          end
        end
        COMPUTE: begin
          if (bit_pos < 4'd15) begin
            parity_bit <= parity_bit ^ data_in[bit_pos];
            bit_pos <= bit_pos + 1'd1;
          end else begin
            parity_bit <= parity_bit ^ data_in[15];
            state <= DONE;
          end
        end
        DONE: begin
          valid <= 1'b1;
          state <= IDLE;
        end
      endcase
    end
  end
endmodule
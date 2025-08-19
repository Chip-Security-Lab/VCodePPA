//SystemVerilog
module priority_parity_gen(
  input clk,
  input rst_n,
  input valid,
  output ready,
  input [15:0] data,
  input [3:0] priority_level,
  output reg parity_result
);
  reg [15:0] masked_data;
  reg data_valid;
  reg [1:0] state;
  
  localparam IDLE = 2'b00;
  localparam PROCESS = 2'b01;
  localparam DONE = 2'b10;
  
  assign ready = (state == IDLE);
  
  always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
      masked_data <= 16'h0000;
      data_valid <= 1'b0;
      parity_result <= 1'b0;
      state <= IDLE;
    end else begin
      case (state)
        IDLE: begin
          if (valid) begin
            masked_data <= 16'h0000;
            for (int i = 0; i < 16; i = i + 1)
              if (i >= priority_level)
                masked_data[i] <= data[i];
            parity_result <= ^masked_data;
            data_valid <= 1'b1;
            state <= PROCESS;
          end
        end
        PROCESS: begin
          data_valid <= 1'b0;
          state <= DONE;
        end
        DONE: begin
          state <= IDLE;
        end
        default: state <= IDLE;
      endcase
    end
  end
endmodule
module uart_error_detect (
  input wire clk, rst_n,
  input wire serial_in,
  output reg [7:0] rx_data,
  output reg data_valid,
  output reg framing_error, parity_error, overrun_error
);
  localparam IDLE = 3'd0, START = 3'd1, DATA = 3'd2, PARITY = 3'd3, STOP = 3'd4;
  reg [2:0] state;
  reg [2:0] bit_count;
  reg [7:0] shift_reg;
  reg parity_bit;
  reg data_ready;
  reg prev_data_ready;
  
  always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
      state <= IDLE;
      bit_count <= 0;
      shift_reg <= 0;
      parity_bit <= 0;
      framing_error <= 0;
      parity_error <= 0;
      overrun_error <= 0;
      data_valid <= 0;
      data_ready <= 0;
      prev_data_ready <= 0;
    end else begin
      prev_data_ready <= data_ready;
      
      case (state)
        IDLE: begin
          if (serial_in == 1'b0) begin
            state <= START;
          end
          if (data_ready && !prev_data_ready) begin
            rx_data <= shift_reg;
            data_valid <= 1;
          end else begin
            data_valid <= 0;
          end
        end
        START: begin
          state <= DATA;
          bit_count <= 0;
          shift_reg <= 0;
          parity_bit <= 0;
        end
        DATA: begin
          shift_reg <= {serial_in, shift_reg[7:1]};
          parity_bit <= parity_bit ^ serial_in; // Calculate odd parity
          if (bit_count == 7) begin
            state <= PARITY;
          end else begin
            bit_count <= bit_count + 1;
          end
        end
        PARITY: begin
          state <= STOP;
          parity_error <= (parity_bit == serial_in); // Odd parity check
        end
        STOP: begin
          state <= IDLE;
          framing_error <= (serial_in == 0); // STOP bit should be 1
          overrun_error <= data_ready && !prev_data_ready && !data_valid;
          data_ready <= 1;
        end
      endcase
    end
  end
endmodule
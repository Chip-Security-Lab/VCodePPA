module uart_baud_gen #(parameter CLK_FREQ = 50_000_000) (
  input wire sys_clk, rst_n,
  input wire [15:0] baud_val, // Desired baud rate
  input wire [7:0] tx_data,
  input wire tx_start,
  output reg tx_out, tx_done
);
  localparam IDLE = 2'b00, START = 2'b01, DATA = 2'b10, STOP = 2'b11;
  reg [1:0] state;
  reg [15:0] baud_counter;
  reg [15:0] bit_duration;
  reg [2:0] bit_idx;
  reg [7:0] tx_reg;
  
  always @(posedge sys_clk or negedge rst_n) begin
    if (!rst_n) begin
      state <= IDLE;
      tx_out <= 1'b1;
      baud_counter <= 0;
      bit_idx <= 0;
      tx_done <= 0;
      bit_duration <= CLK_FREQ / baud_val;
    end else begin
      case (state)
        IDLE: begin
          tx_out <= 1'b1;
          tx_done <= 1'b0;
          if (tx_start) begin
            state <= START;
            tx_reg <= tx_data;
            baud_counter <= 0;
          end
        end
        START: begin
          tx_out <= 1'b0;
          baud_counter <= baud_counter + 1;
          if (baud_counter >= bit_duration-1) begin
            baud_counter <= 0;
            state <= DATA;
            bit_idx <= 0;
          end
        end
        DATA: begin
          tx_out <= tx_reg[bit_idx];
          baud_counter <= baud_counter + 1;
          if (baud_counter >= bit_duration-1) begin
            baud_counter <= 0;
            if (bit_idx == 7) state <= STOP;
            else bit_idx <= bit_idx + 1;
          end
        end
        STOP: begin
          tx_out <= 1'b1;
          baud_counter <= baud_counter + 1;
          if (baud_counter >= bit_duration-1) begin
            state <= IDLE;
            tx_done <= 1'b1;
          end
        end
      endcase
    end
  end
endmodule
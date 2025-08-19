module uart_rx #(parameter DWIDTH = 8, SBIT = 1) (
  input wire clk, rst_n, rx_line,
  output reg rx_ready,
  output reg [DWIDTH-1:0] rx_data,
  output reg frame_err
);
  localparam IDLE = 0, START = 1, DATA = 2, STOP = 3;
  reg [1:0] state;
  reg [3:0] bit_count;
  reg [4:0] clk_count;
  
  always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
      state <= IDLE;
      rx_ready <= 0;
      rx_data <= 0;
      frame_err <= 0;
    end else begin
      case (state)
        IDLE: if (!rx_line) begin state <= START; clk_count <= 0; end
        START: begin 
          clk_count <= clk_count + 1;
          if (clk_count == 7) begin state <= DATA; bit_count <= 0; end
        end
        DATA: begin
          clk_count <= clk_count + 1;
          if (clk_count == 15) begin
            clk_count <= 0;
            rx_data <= {rx_line, rx_data[DWIDTH-1:1]};
            bit_count <= bit_count + 1;
            if (bit_count == DWIDTH-1) state <= STOP;
          end
        end
        STOP: begin
          clk_count <= clk_count + 1;
          if (clk_count == 15) begin
            state <= IDLE;
            rx_ready <= 1;
            frame_err <= !rx_line;
          end
        end
      endcase
    end
  end
endmodule
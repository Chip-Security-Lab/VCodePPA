//SystemVerilog
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

  // Forward retiming: Move input register after combinational logic
  reg rx_line_sync1, rx_line_sync2;
  always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
      rx_line_sync1 <= 1'b1;
      rx_line_sync2 <= 1'b1;
    end else begin
      rx_line_sync1 <= rx_line;
      rx_line_sync2 <= rx_line_sync1;
    end
  end

  wire rx_line_sampled = rx_line_sync2;

  // Retimed FSM and datapath
  reg [4:0] clk_count_nxt;
  reg [3:0] bit_count_nxt;
  reg [DWIDTH-1:0] rx_data_nxt;
  reg [1:0] state_nxt;
  reg rx_ready_nxt;
  reg frame_err_nxt;

  always @* begin
    // Default assignments
    state_nxt      = state;
    clk_count_nxt  = clk_count;
    bit_count_nxt  = bit_count;
    rx_data_nxt    = rx_data;
    rx_ready_nxt   = 1'b0;
    frame_err_nxt  = frame_err;

    case (state)
      IDLE: begin
        if (!rx_line_sampled) begin
          state_nxt     = START;
          clk_count_nxt = 0;
        end
      end
      START: begin 
        clk_count_nxt = clk_count + 1;
        if (clk_count == 7) begin
          state_nxt     = DATA;
          bit_count_nxt = 0;
        end
      end
      DATA: begin
        clk_count_nxt = clk_count + 1;
        if (clk_count == 15) begin
          clk_count_nxt = 0;
          rx_data_nxt   = {rx_line_sampled, rx_data[DWIDTH-1:1]};
          bit_count_nxt = bit_count + 1;
          if (bit_count == DWIDTH-1)
            state_nxt = STOP;
        end
      end
      STOP: begin
        clk_count_nxt = clk_count + 1;
        if (clk_count == 15) begin
          state_nxt     = IDLE;
          rx_ready_nxt  = 1'b1;
          frame_err_nxt = !rx_line_sampled;
        end
      end
    endcase
  end

  always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
      state      <= IDLE;
      rx_ready   <= 1'b0;
      rx_data    <= {DWIDTH{1'b0}};
      frame_err  <= 1'b0;
      clk_count  <= 5'd0;
      bit_count  <= 4'd0;
    end else begin
      state      <= state_nxt;
      clk_count  <= clk_count_nxt;
      bit_count  <= bit_count_nxt;
      rx_data    <= rx_data_nxt;
      rx_ready   <= rx_ready_nxt;
      frame_err  <= frame_err_nxt;
    end
  end

endmodule
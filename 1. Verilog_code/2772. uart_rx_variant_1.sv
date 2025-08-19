//SystemVerilog
module uart_rx #(parameter DWIDTH = 8, SBIT = 1) (
  input wire clk,
  input wire rst_n,
  input wire rx_line,
  output reg rx_ready,
  output reg [DWIDTH-1:0] rx_data,
  output reg frame_err
);

  // FSM states
  localparam IDLE = 2'd0, START = 2'd1, DATA = 2'd2, STOP = 2'd3;

  reg [1:0] state_stage1, state_stage2, state_stage3;
  reg [3:0] bit_count_stage1, bit_count_stage2, bit_count_stage3;
  reg [4:0] clk_count_stage1, clk_count_stage2, clk_count_stage3, clk_count_stage4;
  reg [DWIDTH-1:0] rx_data_stage1, rx_data_stage2, rx_data_stage3;
  reg rx_line_stage1, rx_line_stage2, rx_line_stage3;
  reg rx_ready_stage1, rx_ready_stage2, rx_ready_stage3;
  reg frame_err_stage1, frame_err_stage2, frame_err_stage3;

  // Pipeline register for rx_line
  always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
      rx_line_stage1 <= 1'b1;
      rx_line_stage2 <= 1'b1;
      rx_line_stage3 <= 1'b1;
    end else begin
      rx_line_stage1 <= rx_line;
      rx_line_stage2 <= rx_line_stage1;
      rx_line_stage3 <= rx_line_stage2;
    end
  end

  // Stage 1: FSM state, bit_count, clk_count, rx_data
  always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
      state_stage1 <= IDLE;
      bit_count_stage1 <= 4'd0;
      clk_count_stage1 <= 5'd0;
      rx_data_stage1 <= {DWIDTH{1'b0}};
      rx_ready_stage1 <= 1'b0;
      frame_err_stage1 <= 1'b0;
    end else begin
      case (state_stage1)
        IDLE: begin
          rx_ready_stage1 <= 1'b0;
          if (!rx_line_stage1) begin
            state_stage1 <= START;
            clk_count_stage1 <= 5'd0;
            bit_count_stage1 <= 4'd0;
          end else begin
            state_stage1 <= IDLE;
            clk_count_stage1 <= 5'd0;
            bit_count_stage1 <= 4'd0;
          end
        end
        START: begin
          clk_count_stage1 <= clk_count_stage1 + 5'd1;
          if (clk_count_stage1 == 5'd7) begin
            state_stage1 <= DATA;
            bit_count_stage1 <= 4'd0;
            clk_count_stage1 <= 5'd0;
          end
        end
        DATA: begin
          clk_count_stage1 <= clk_count_stage1 + 5'd1;
          if (clk_count_stage1 == 5'd15) begin
            clk_count_stage1 <= 5'd0;
            rx_data_stage1 <= {rx_line_stage1, rx_data_stage1[DWIDTH-1:1]};
            bit_count_stage1 <= bit_count_stage1 + 4'd1;
            if (bit_count_stage1 == DWIDTH-1)
              state_stage1 <= STOP;
          end
        end
        STOP: begin
          clk_count_stage1 <= clk_count_stage1 + 5'd1;
          if (clk_count_stage1 == 5'd15) begin
            state_stage1 <= IDLE;
            rx_ready_stage1 <= 1'b1;
            frame_err_stage1 <= ~rx_line_stage1;
          end
        end
        default: begin
          state_stage1 <= IDLE;
        end
      endcase
    end
  end

  // Stage 2: Pipeline register
  always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
      state_stage2 <= IDLE;
      bit_count_stage2 <= 4'd0;
      clk_count_stage2 <= 5'd0;
      rx_data_stage2 <= {DWIDTH{1'b0}};
      rx_ready_stage2 <= 1'b0;
      frame_err_stage2 <= 1'b0;
    end else begin
      state_stage2        <= state_stage1;
      bit_count_stage2    <= bit_count_stage1;
      clk_count_stage2    <= clk_count_stage1;
      rx_data_stage2      <= rx_data_stage1;
      rx_ready_stage2     <= rx_ready_stage1;
      frame_err_stage2    <= frame_err_stage1;
    end
  end

  // Stage 3: Pipeline register
  always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
      state_stage3 <= IDLE;
      bit_count_stage3 <= 4'd0;
      clk_count_stage3 <= 5'd0;
      rx_data_stage3 <= {DWIDTH{1'b0}};
      rx_ready_stage3 <= 1'b0;
      frame_err_stage3 <= 1'b0;
    end else begin
      state_stage3        <= state_stage2;
      bit_count_stage3    <= bit_count_stage2;
      clk_count_stage3    <= clk_count_stage2;
      rx_data_stage3      <= rx_data_stage2;
      rx_ready_stage3     <= rx_ready_stage2;
      frame_err_stage3    <= frame_err_stage2;
    end
  end

  // Stage 4: Output register
  always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
      rx_ready <= 1'b0;
      rx_data <= {DWIDTH{1'b0}};
      frame_err <= 1'b0;
    end else begin
      rx_ready <= rx_ready_stage3;
      rx_data <= rx_data_stage3;
      frame_err <= frame_err_stage3;
    end
  end

endmodule
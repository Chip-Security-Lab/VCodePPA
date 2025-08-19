//SystemVerilog
module mipi_dphy_lp_controller (
  input wire clk, reset_n,
  input wire [1:0] lp_mode,
  input wire enable_lpdt,
  input wire [7:0] lpdt_data,
  output reg [1:0] lp_out,
  output reg lpdt_done
);

  reg [2:0] state, next_state;
  reg [7:0] shift_reg;
  reg [3:0] bit_count;
  reg [1:0] next_lp_out;
  reg next_lpdt_done;
  
  // State encoding
  localparam IDLE = 3'd0;
  localparam LPDT_START = 3'd1;
  localparam LPDT_DATA = 3'd2;
  localparam LPDT_STOP = 3'd3;
  
  // Combinational logic for next state and outputs
  always @(*) begin
    next_state = state;
    next_lp_out = lp_out;
    next_lpdt_done = 1'b0;
    
    case (state)
      IDLE: begin
        if (lp_mode != 2'b00) next_lp_out = lp_mode;
        if (enable_lpdt) next_state = LPDT_START;
      end
      LPDT_START: begin
        next_lp_out = 2'b01;
        next_state = LPDT_DATA;
      end
      LPDT_DATA: begin
        next_lp_out = shift_reg[7] ? 2'b10 : 2'b01;
        if (bit_count == 4'd7) next_state = LPDT_STOP;
      end
      LPDT_STOP: begin
        next_lp_out = 2'b11;
        next_lpdt_done = 1'b1;
        next_state = IDLE;
      end
    endcase
  end
  
  // Sequential logic
  always @(posedge clk or negedge reset_n) begin
    if (!reset_n) begin
      state <= IDLE;
      lp_out <= 2'b11;
      lpdt_done <= 1'b0;
      bit_count <= 4'd0;
      shift_reg <= 8'd0;
    end else begin
      state <= next_state;
      lp_out <= next_lp_out;
      lpdt_done <= next_lpdt_done;
      
      if (state == IDLE && enable_lpdt) begin
        shift_reg <= lpdt_data;
        bit_count <= 4'd0;
      end else if (state == LPDT_DATA) begin
        shift_reg <= {shift_reg[6:0], 1'b0};
        bit_count <= bit_count + 1'b1;
      end
    end
  end
endmodule
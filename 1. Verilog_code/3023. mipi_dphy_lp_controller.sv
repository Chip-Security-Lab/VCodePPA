module mipi_dphy_lp_controller (
  input wire clk, reset_n,
  input wire [1:0] lp_mode, // 00: HS, 01: LP-11, 10: LP-01, 11: LP-00
  input wire enable_lpdt,
  input wire [7:0] lpdt_data,
  output reg [1:0] lp_out,
  output reg lpdt_done
);
  reg [2:0] state;
  reg [7:0] shift_reg;
  reg [3:0] bit_count;
  
  always @(posedge clk or negedge reset_n) begin
    if (!reset_n) begin
      state <= 3'd0;
      lp_out <= 2'b11; // LP-11 (idle)
      lpdt_done <= 1'b0;
      bit_count <= 4'd0;
    end else case (state)
      3'd0: begin // IDLE
        if (lp_mode != 2'b00) lp_out <= lp_mode;
        if (enable_lpdt) begin
          state <= 3'd1;
          shift_reg <= lpdt_data;
          bit_count <= 4'd0;
        end
      end
      3'd1: begin // LPDT START
        lp_out <= 2'b01; // LP-01
        state <= 3'd2;
      end
      3'd2: begin // LPDT DATA
        lp_out <= shift_reg[7] ? 2'b10 : 2'b01;
        shift_reg <= {shift_reg[6:0], 1'b0};
        bit_count <= bit_count + 1'b1;
        if (bit_count == 4'd7) state <= 3'd3;
      end
      3'd3: begin // LPDT STOP
        lp_out <= 2'b11; // LP-11
        lpdt_done <= 1'b1;
        state <= 3'd0;
      end
    endcase
  end
endmodule
//SystemVerilog
module mipi_dphy_lp_controller (
  input wire clk, reset_n,
  input wire [1:0] lp_mode,
  input wire enable_lpdt,
  input wire [7:0] lpdt_data,
  output reg [1:0] lp_out,
  output reg lpdt_done
);

  // Pipeline stage 1 registers
  reg [2:0] state_stage1;
  reg [7:0] shift_reg_stage1;
  reg [3:0] bit_count_stage1;
  reg [1:0] lp_mode_stage1;
  reg enable_lpdt_stage1;
  reg [7:0] lpdt_data_stage1;
  reg valid_stage1;

  // Pipeline stage 2 registers
  reg [2:0] state_stage2;
  reg [7:0] shift_reg_stage2;
  reg [3:0] bit_count_stage2;
  reg [1:0] lp_out_stage2;
  reg valid_stage2;

  // Pipeline stage 3 registers
  reg [2:0] state_stage3;
  reg [7:0] shift_reg_stage3;
  reg [3:0] bit_count_stage3;
  reg [1:0] lp_out_stage3;
  reg lpdt_done_stage3;
  reg valid_stage3;

  // Stage 1: Input sampling and state transition
  always @(posedge clk or negedge reset_n) begin
    if (!reset_n) begin
      state_stage1 <= 3'd0;
      shift_reg_stage1 <= 8'd0;
      bit_count_stage1 <= 4'd0;
      lp_mode_stage1 <= 2'b11;
      enable_lpdt_stage1 <= 1'b0;
      lpdt_data_stage1 <= 8'd0;
      valid_stage1 <= 1'b0;
    end else begin
      lp_mode_stage1 <= lp_mode;
      enable_lpdt_stage1 <= enable_lpdt;
      lpdt_data_stage1 <= lpdt_data;
      valid_stage1 <= 1'b1;

      case (state_stage1)
        3'd0: begin
          if (enable_lpdt_stage1) begin
            state_stage1 <= 3'd1;
            shift_reg_stage1 <= lpdt_data_stage1;
            bit_count_stage1 <= 4'd0;
          end
        end
        3'd1: state_stage1 <= 3'd2;
        3'd2: begin
          shift_reg_stage1 <= {shift_reg_stage1[6:0], 1'b0};
          bit_count_stage1 <= bit_count_stage1 + 1'b1;
          if (bit_count_stage1 == 4'd7) state_stage1 <= 3'd3;
        end
        3'd3: state_stage1 <= 3'd0;
      endcase
    end
  end

  // Stage 2: Data processing
  always @(posedge clk or negedge reset_n) begin
    if (!reset_n) begin
      state_stage2 <= 3'd0;
      shift_reg_stage2 <= 8'd0;
      bit_count_stage2 <= 4'd0;
      lp_out_stage2 <= 2'b11;
      valid_stage2 <= 1'b0;
    end else if (valid_stage1) begin
      state_stage2 <= state_stage1;
      shift_reg_stage2 <= shift_reg_stage1;
      bit_count_stage2 <= bit_count_stage1;
      valid_stage2 <= 1'b1;

      case (state_stage1)
        3'd0: lp_out_stage2 <= (lp_mode_stage1 != 2'b00) ? lp_mode_stage1 : 2'b11;
        3'd1: lp_out_stage2 <= 2'b01;
        3'd2: lp_out_stage2 <= shift_reg_stage1[7] ? 2'b10 : 2'b01;
        3'd3: lp_out_stage2 <= 2'b11;
      endcase
    end
  end

  // Stage 3: Output generation
  always @(posedge clk or negedge reset_n) begin
    if (!reset_n) begin
      state_stage3 <= 3'd0;
      shift_reg_stage3 <= 8'd0;
      bit_count_stage3 <= 4'd0;
      lp_out <= 2'b11;
      lpdt_done <= 1'b0;
      valid_stage3 <= 1'b0;
    end else if (valid_stage2) begin
      state_stage3 <= state_stage2;
      shift_reg_stage3 <= shift_reg_stage2;
      bit_count_stage3 <= bit_count_stage2;
      lp_out <= lp_out_stage2;
      valid_stage3 <= 1'b1;

      lpdt_done <= (state_stage2 == 3'd3);
    end
  end

endmodule
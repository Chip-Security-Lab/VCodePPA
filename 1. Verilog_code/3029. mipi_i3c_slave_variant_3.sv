//SystemVerilog
module mipi_i3c_slave #(parameter ADDR = 7'h27) (
  input wire scl, reset_n,
  inout wire sda,
  output reg [7:0] rx_data,
  output reg new_data,
  input wire [7:0] tx_data,
  output reg busy
);
  // State definitions
  localparam IDLE = 3'd0, ADDRESS = 3'd1, ACK_ADDR = 3'd2;
  localparam RX = 3'd3, TX = 3'd4, ACK_DATA = 3'd5;
  
  // Pipeline stage registers
  reg [2:0] state_stage1, state_stage2, state_stage3;
  reg [7:0] shift_reg_stage1, shift_reg_stage2;
  reg [3:0] bit_count_stage1, bit_count_stage2;
  reg sda_out_stage1, sda_out_stage2, sda_out_stage3;
  reg sda_oe_stage1, sda_oe_stage2, sda_oe_stage3;
  reg direction_stage1, direction_stage2;
  reg [7:0] rx_data_stage1, rx_data_stage2;
  reg new_data_stage1, new_data_stage2;
  reg busy_stage1, busy_stage2;
  
  // Current state and control signals
  reg [2:0] state;
  reg [7:0] shift_reg;
  reg [3:0] bit_count;
  reg sda_out, sda_oe;
  reg direction;
  
  assign sda = sda_oe ? sda_out : 1'bz;
  
  reg sda_prev_stage1, sda_prev_stage2;
  reg scl_high_stage1, scl_high_stage2;
  wire start_cond = scl_high_stage2 && sda_prev_stage2 && !sda;
  wire stop_cond = scl_high_stage2 && !sda_prev_stage2 && sda;
  
  always @(negedge scl or negedge reset_n) begin
    if (!reset_n) begin
      sda_prev_stage1 <= 1'b1;
      scl_high_stage1 <= 1'b0;
    end else begin
      sda_prev_stage1 <= sda;
      scl_high_stage1 <= 1'b1;
    end
  end
  
  always @(posedge scl or negedge reset_n) begin
    if (!reset_n) begin
      sda_prev_stage2 <= 1'b1;
      scl_high_stage2 <= 1'b0;
      state_stage1 <= IDLE;
      sda_oe_stage1 <= 1'b0;
      new_data_stage1 <= 1'b0;
      busy_stage1 <= 1'b0;
      shift_reg_stage1 <= 8'h00;
      bit_count_stage1 <= 4'd0;
      direction_stage1 <= 1'b0;
      rx_data_stage1 <= 8'h00;
    end else begin
      sda_prev_stage2 <= sda_prev_stage1;
      scl_high_stage2 <= scl_high_stage1;
      
      state_stage1 <= state;
      sda_oe_stage1 <= sda_oe;
      new_data_stage1 <= new_data;
      busy_stage1 <= busy;
      shift_reg_stage1 <= shift_reg;
      bit_count_stage1 <= bit_count;
      direction_stage1 <= direction;
      rx_data_stage1 <= rx_data;
      
      if (stop_cond) begin
        state_stage1 <= IDLE;
        busy_stage1 <= 1'b0;
        sda_oe_stage1 <= 1'b0;
      end
    end
  end
  
  always @(posedge scl or negedge reset_n) begin
    if (!reset_n) begin
      state_stage2 <= IDLE;
      sda_oe_stage2 <= 1'b0;
      new_data_stage2 <= 1'b0;
      busy_stage2 <= 1'b0;
      shift_reg_stage2 <= 8'h00;
      bit_count_stage2 <= 4'd0;
      direction_stage2 <= 1'b0;
      rx_data_stage2 <= 8'h00;
      sda_out_stage1 <= 1'b0;
    end else begin
      state_stage2 <= state_stage1;
      sda_oe_stage2 <= sda_oe_stage1;
      new_data_stage2 <= new_data_stage1;
      busy_stage2 <= busy_stage1;
      shift_reg_stage2 <= shift_reg_stage1;
      bit_count_stage2 <= bit_count_stage1;
      direction_stage2 <= direction_stage1;
      rx_data_stage2 <= rx_data_stage1;
      sda_out_stage1 <= sda_out;
      
      if (state_stage1 == IDLE) begin
        if (start_cond) begin
          state_stage2 <= ADDRESS;
          bit_count_stage2 <= 4'd0;
          busy_stage2 <= 1'b1;
        end
      end else if (state_stage1 == ADDRESS) begin
        shift_reg_stage2 <= {shift_reg_stage1[6:0], sda};
        bit_count_stage2 <= bit_count_stage1 + 1'b1;
        if (bit_count_stage1 == 4'd7) begin
          state_stage2 <= ACK_ADDR;
          direction_stage2 <= sda;
        end
      end else if (state_stage1 == ACK_ADDR) begin
        if (shift_reg_stage1[7:1] == ADDR) begin
          sda_oe_stage2 <= 1'b1;
          sda_out_stage1 <= 1'b0;
          state_stage2 <= direction_stage1 ? TX : RX;
          bit_count_stage2 <= 4'd0;
          rx_data_stage2 <= 8'h00;
        end else begin
          sda_oe_stage2 <= 1'b0;
          state_stage2 <= IDLE;
          busy_stage2 <= 1'b0;
        end
      end else if (state_stage1 == RX) begin
        sda_oe_stage2 <= 1'b0;
        rx_data_stage2 <= {rx_data_stage1[6:0], sda};
        bit_count_stage2 <= bit_count_stage1 + 1'b1;
        if (bit_count_stage1 == 4'd7) begin
          state_stage2 <= ACK_DATA;
          new_data_stage2 <= 1'b1;
        end
      end else if (state_stage1 == TX) begin
        sda_oe_stage2 <= 1'b1;
        sda_out_stage1 <= tx_data[7-bit_count_stage1];
        bit_count_stage2 <= bit_count_stage1 + 1'b1;
        if (bit_count_stage1 == 4'd7) begin
          state_stage2 <= ACK_DATA;
        end
      end else if (state_stage1 == ACK_DATA) begin
        if (direction_stage1) begin
          sda_oe_stage2 <= 1'b0;
          if (sda == 1'b1) begin
            state_stage2 <= IDLE;
            busy_stage2 <= 1'b0;
          end else begin
            state_stage2 <= TX;
            bit_count_stage2 <= 4'd0;
          end
        end else begin
          sda_oe_stage2 <= 1'b1;
          sda_out_stage1 <= 1'b0;
          state_stage2 <= RX;
          bit_count_stage2 <= 4'd0;
          new_data_stage2 <= 1'b0;
        end
      end else begin
        state_stage2 <= IDLE;
      end
    end
  end
  
  always @(posedge scl or negedge reset_n) begin
    if (!reset_n) begin
      state <= IDLE;
      sda_oe <= 1'b0;
      new_data <= 1'b0;
      busy <= 1'b0;
      shift_reg <= 8'h00;
      bit_count <= 4'd0;
      direction <= 1'b0;
      rx_data <= 8'h00;
      sda_out <= 1'b0;
    end else begin
      state <= state_stage2;
      sda_oe <= sda_oe_stage2;
      new_data <= new_data_stage2;
      busy <= busy_stage2;
      shift_reg <= shift_reg_stage2;
      bit_count <= bit_count_stage2;
      direction <= direction_stage2;
      rx_data <= rx_data_stage2;
      sda_out <= sda_out_stage1;
    end
  end
endmodule
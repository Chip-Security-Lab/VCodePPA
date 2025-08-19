//SystemVerilog
module mipi_i3c_slave #(parameter ADDR = 7'h27) (
  input wire scl, reset_n,
  inout wire sda,
  output reg [7:0] rx_data,
  output reg new_data,
  input wire [7:0] tx_data,
  output reg busy
);
  localparam IDLE = 3'd0, ADDRESS = 3'd1, ACK_ADDR = 3'd2;
  localparam RX = 3'd3, TX = 3'd4, ACK_DATA = 3'd5;
  
  reg [2:0] state, next_state;
  reg [7:0] shift_reg, next_shift_reg;
  reg [3:0] bit_count, next_bit_count;
  reg sda_out, next_sda_out;
  reg sda_oe, next_sda_oe;
  reg direction, next_direction;
  reg [7:0] next_rx_data;
  reg next_new_data;
  reg next_busy;
  
  assign sda = sda_oe ? sda_out : 1'bz;
  
  reg sda_prev, next_sda_prev;
  reg scl_high, next_scl_high;
  wire start_cond = scl_high && sda_prev && !sda;
  wire stop_cond = scl_high && !sda_prev && sda;
  
  // Stage 1: Input sampling and condition detection
  always @(negedge scl or negedge reset_n) begin
    if (!reset_n) begin
      sda_prev <= 1'b1;
      scl_high <= 1'b0;
    end else begin
      sda_prev <= sda;
      scl_high <= 1'b1;
    end
  end
  
  // Stage 2: State transition and control logic
  always @(*) begin
    next_state = state;
    next_shift_reg = shift_reg;
    next_bit_count = bit_count;
    next_sda_oe = sda_oe;
    next_sda_out = sda_out;
    next_direction = direction;
    next_rx_data = rx_data;
    next_new_data = new_data;
    next_busy = busy;
    
    case (state)
      IDLE: begin
        if (start_cond) begin
          next_state = ADDRESS;
          next_bit_count = 4'd0;
          next_busy = 1'b1;
        end
      end
      
      ADDRESS: begin
        next_shift_reg = {shift_reg[6:0], sda};
        next_bit_count = bit_count + 1'b1;
        if (bit_count == 4'd7) begin
          next_state = ACK_ADDR;
          next_direction = sda;
        end
      end
      
      ACK_ADDR: begin
        if (shift_reg[7:1] == ADDR) begin
          next_sda_oe = 1'b1;
          next_sda_out = 1'b0;
          next_state = direction ? TX : RX;
          next_bit_count = 4'd0;
          next_rx_data = 8'h00;
        end else begin
          next_sda_oe = 1'b0;
          next_state = IDLE;
          next_busy = 1'b0;
        end
      end
      
      RX: begin
        next_sda_oe = 1'b0;
        next_rx_data = {rx_data[6:0], sda};
        next_bit_count = bit_count + 1'b1;
        if (bit_count == 4'd7) begin
          next_state = ACK_DATA;
          next_new_data = 1'b1;
        end
      end
      
      TX: begin
        next_sda_oe = 1'b1;
        next_sda_out = tx_data[7-bit_count];
        next_bit_count = bit_count + 1'b1;
        if (bit_count == 4'd7) begin
          next_state = ACK_DATA;
        end
      end
      
      ACK_DATA: begin
        if (direction) begin
          next_sda_oe = 1'b0;
          if (sda == 1'b1) begin
            next_state = IDLE;
            next_busy = 1'b0;
          end else begin
            next_state = TX;
            next_bit_count = 4'd0;
          end
        end else begin
          next_sda_oe = 1'b1;
          next_sda_out = 1'b0;
          next_state = RX;
          next_bit_count = 4'd0;
          next_new_data = 1'b0;
        end
      end
      
      default: begin
        next_state = IDLE;
      end
    endcase
    
    if (stop_cond) begin
      next_state = IDLE;
      next_busy = 1'b0;
      next_sda_oe = 1'b0;
    end
  end
  
  // Stage 3: Register update with retiming
  reg [7:0] rx_data_reg;
  reg new_data_reg;
  reg busy_reg;
  
  always @(posedge scl or negedge reset_n) begin
    if (!reset_n) begin
      state <= IDLE;
      sda_oe <= 1'b0;
      new_data_reg <= 1'b0;
      busy_reg <= 1'b0;
      shift_reg <= 8'h00;
      bit_count <= 4'd0;
      direction <= 1'b0;
      rx_data_reg <= 8'h00;
      rx_data <= 8'h00;
      new_data <= 1'b0;
      busy <= 1'b0;
    end else begin
      state <= next_state;
      shift_reg <= next_shift_reg;
      bit_count <= next_bit_count;
      sda_oe <= next_sda_oe;
      sda_out <= next_sda_out;
      direction <= next_direction;
      rx_data_reg <= next_rx_data;
      new_data_reg <= next_new_data;
      busy_reg <= next_busy;
      
      // Retimed output registers
      rx_data <= rx_data_reg;
      new_data <= new_data_reg;
      busy <= busy_reg;
    end
  end
endmodule
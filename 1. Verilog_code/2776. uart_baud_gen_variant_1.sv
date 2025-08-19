//SystemVerilog
module uart_baud_gen #(parameter CLK_FREQ = 50_000_000) (
  input wire sys_clk, rst_n,
  input wire [15:0] baud_val, // Desired baud rate
  input wire [7:0] tx_data,
  input wire tx_start,
  output reg tx_out, tx_done
);
  // State definitions with expanded pipeline stages
  localparam IDLE = 3'b000, START_PREP = 3'b001, START_TX = 3'b010;
  localparam DATA_PREP = 3'b011, DATA_TX = 3'b100, STOP_PREP = 3'b101, STOP_TX = 3'b110;
  
  reg [2:0] state, next_state;
  reg [15:0] baud_counter, baud_counter_next;
  reg [15:0] bit_duration;
  reg [2:0] bit_idx, bit_idx_next;
  reg [7:0] tx_reg, tx_reg_next;
  reg tx_out_next, tx_done_next;
  
  // State transition logic
  always @(*) begin
    next_state = state;
    
    case (state)
      IDLE: begin
        if (tx_start) begin
          next_state = START_PREP;
        end
      end
      
      START_PREP: begin
        next_state = START_TX;
      end
      
      START_TX: begin
        if (baud_counter >= bit_duration-1) begin
          next_state = DATA_PREP;
        end
      end
      
      DATA_PREP: begin
        next_state = DATA_TX;
      end
      
      DATA_TX: begin
        if (baud_counter >= bit_duration-1) begin
          if (bit_idx == 7) begin
            next_state = STOP_PREP;
          end else begin
            next_state = DATA_PREP;
          end
        end
      end
      
      STOP_PREP: begin
        next_state = STOP_TX;
      end
      
      STOP_TX: begin
        if (baud_counter >= bit_duration-1) begin
          next_state = IDLE;
        end
      end
    endcase
  end
  
  // Baud counter control logic
  always @(*) begin
    baud_counter_next = baud_counter + 1'b1;
    
    case (state)
      IDLE: begin
        baud_counter_next = 0;
      end
      
      START_PREP: begin
        baud_counter_next = 0;
      end
      
      START_TX: begin
        if (baud_counter >= bit_duration-1) begin
          baud_counter_next = 0;
        end
      end
      
      DATA_PREP: begin
        baud_counter_next = 0;
      end
      
      DATA_TX: begin
        if (baud_counter >= bit_duration-1) begin
          baud_counter_next = 0;
        end
      end
      
      STOP_PREP: begin
        baud_counter_next = 0;
      end
      
      STOP_TX: begin
        if (baud_counter >= bit_duration-1) begin
          baud_counter_next = 0;
        end
      end
    endcase
  end
  
  // Bit index control logic
  always @(*) begin
    bit_idx_next = bit_idx;
    
    case (state)
      START_TX: begin
        if (baud_counter >= bit_duration-1) begin
          bit_idx_next = 0;
        end
      end
      
      DATA_TX: begin
        if (baud_counter >= bit_duration-1 && bit_idx != 7) begin
          bit_idx_next = bit_idx + 1'b1;
        end
      end
    endcase
  end
  
  // TX data register control logic
  always @(*) begin
    tx_reg_next = tx_reg;
    
    case (state)
      IDLE: begin
        if (tx_start) begin
          tx_reg_next = tx_data;
        end
      end
    endcase
  end
  
  // TX output control logic
  always @(*) begin
    tx_out_next = tx_out;
    
    case (state)
      IDLE: begin
        tx_out_next = 1'b1;
      end
      
      START_PREP: begin
        tx_out_next = 1'b0;
      end
      
      START_TX: begin
        tx_out_next = 1'b0;
      end
      
      DATA_PREP: begin
        tx_out_next = tx_reg[bit_idx];
      end
      
      DATA_TX: begin
        tx_out_next = tx_reg[bit_idx];
      end
      
      STOP_PREP: begin
        tx_out_next = 1'b1;
      end
      
      STOP_TX: begin
        tx_out_next = 1'b1;
      end
    endcase
  end
  
  // TX done signal control logic
  always @(*) begin
    tx_done_next = 1'b0;
    
    case (state)
      STOP_TX: begin
        if (baud_counter >= bit_duration-1) begin
          tx_done_next = 1'b1;
        end
      end
    endcase
  end
  
  // Sequential logic for state updates
  always @(posedge sys_clk or negedge rst_n) begin
    if (!rst_n) begin
      state <= IDLE;
      baud_counter <= 0;
      bit_idx <= 0;
      tx_reg <= 0;
    end else begin
      state <= next_state;
      baud_counter <= baud_counter_next;
      bit_idx <= bit_idx_next;
      tx_reg <= tx_reg_next;
    end
  end
  
  // Sequential logic for output signals
  always @(posedge sys_clk or negedge rst_n) begin
    if (!rst_n) begin
      tx_out <= 1'b1;
      tx_done <= 1'b0;
    end else begin
      tx_out <= tx_out_next;
      tx_done <= tx_done_next;
    end
  end
  
  // Bit duration calculation logic - only update in IDLE state
  always @(posedge sys_clk or negedge rst_n) begin
    if (!rst_n) begin
      bit_duration <= CLK_FREQ / baud_val;
    end else if (state == IDLE) begin
      bit_duration <= CLK_FREQ / baud_val;
    end
  end
endmodule
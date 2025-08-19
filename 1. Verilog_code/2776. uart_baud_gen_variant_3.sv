//SystemVerilog
module uart_baud_gen #(parameter CLK_FREQ = 50_000_000) (
  input wire sys_clk, rst_n,
  input wire [15:0] baud_val, // Desired baud rate
  input wire [7:0] tx_data,
  input wire tx_start,
  output reg tx_out, tx_done
);
  localparam IDLE = 2'b00, START = 2'b01, DATA = 2'b10, STOP = 2'b11;
  
  reg [1:0] state, state_pipe;
  reg [15:0] baud_counter, baud_counter_pipe;
  reg [15:0] bit_duration, bit_duration_pipe;
  reg [2:0] bit_idx, bit_idx_pipe;
  reg [7:0] tx_reg, tx_reg_pipe;
  reg tx_out_next;
  reg tx_done_next;
  
  // Pre-calculate comparison results to break critical path
  reg baud_count_expired;
  reg bit_idx_complete;
  
  // Binary long division algorithm signals
  reg [15:0] dividend;        // Numerator (CLK_FREQ)
  reg [15:0] divisor;         // Denominator (baud_val)
  reg [15:0] quotient;        // Result
  reg [15:0] remainder;
  reg [4:0] div_counter;      // Counter for 16 iterations
  reg div_busy;               // Division in progress
  reg div_done;               // Division completed
  reg div_start;              // Start division
  
  // Long division state machine
  localparam DIV_IDLE = 2'b00, DIV_CALC = 2'b01, DIV_DONE = 2'b10;
  reg [1:0] div_state;
  
  // Division state machine
  always @(posedge sys_clk or negedge rst_n) begin
    if (!rst_n) begin
      div_state <= DIV_IDLE;
      div_busy <= 1'b0;
      div_done <= 1'b0;
      div_counter <= 5'd0;
      quotient <= 16'd0;
      remainder <= 16'd0;
      dividend <= 16'd0;
      divisor <= 16'd0;
    end else begin
      case (div_state)
        DIV_IDLE: begin
          div_done <= 1'b0;
          if (div_start) begin
            div_state <= DIV_CALC;
            div_busy <= 1'b1;
            div_counter <= 5'd16;  // 16 iterations for 16-bit division
            quotient <= 16'd0;
            remainder <= 16'd0;
            dividend <= CLK_FREQ[15:0];  // Use parameter as dividend
            divisor <= baud_val;
          end
        end
        
        DIV_CALC: begin
          if (div_counter > 0) begin
            // Shift dividend bit into remainder
            remainder <= {remainder[14:0], dividend[15]};
            dividend <= {dividend[14:0], 1'b0};
            
            // Check if remainder >= divisor
            if ({remainder[14:0], dividend[15]} >= divisor) begin
              remainder <= {remainder[14:0], dividend[15]} - divisor;
              quotient <= {quotient[14:0], 1'b1};
            end else begin
              quotient <= {quotient[14:0], 1'b0};
            end
            
            div_counter <= div_counter - 1'b1;
          end else begin
            div_state <= DIV_DONE;
            div_busy <= 1'b0;
            div_done <= 1'b1;
          end
        end
        
        DIV_DONE: begin
          div_done <= 1'b0;
          div_state <= DIV_IDLE;
        end
      endcase
    end
  end
  
  // Trigger division when baud_val changes
  reg [15:0] prev_baud_val;
  always @(posedge sys_clk or negedge rst_n) begin
    if (!rst_n) begin
      prev_baud_val <= 16'd0;
      div_start <= 1'b1;  // Initial division
    end else begin
      div_start <= 1'b0;
      if (prev_baud_val != baud_val) begin
        prev_baud_val <= baud_val;
        div_start <= 1'b1;  // Start division when baud_val changes
      end
    end
  end
  
  // First stage: Calculate comparison flags
  always @(posedge sys_clk or negedge rst_n) begin
    if (!rst_n) begin
      baud_count_expired <= 1'b0;
      bit_idx_complete <= 1'b0;
    end else begin
      // Pre-calculate comparison results
      baud_count_expired <= (baud_counter >= bit_duration-1);
      bit_idx_complete <= (bit_idx == 7);
    end
  end
  
  // Second stage: Main state machine with reduced combinational logic
  always @(posedge sys_clk or negedge rst_n) begin
    if (!rst_n) begin
      state <= IDLE;
      tx_out <= 1'b1;
      baud_counter <= 0;
      bit_idx <= 0;
      tx_done <= 0;
      bit_duration <= 16'd5208; // Default value (50MHz/9600)
      
      // Pipeline registers reset
      state_pipe <= IDLE;
      baud_counter_pipe <= 0;
      bit_duration_pipe <= 16'd5208;
      bit_idx_pipe <= 0;
      tx_reg_pipe <= 0;
      tx_out_next <= 1'b1;
      tx_done_next <= 1'b0;
    end else begin
      // Pipeline stage
      state_pipe <= state;
      baud_counter_pipe <= baud_counter;
      bit_duration_pipe <= bit_duration;
      bit_idx_pipe <= bit_idx;
      tx_reg_pipe <= tx_reg;
      tx_out <= tx_out_next;
      tx_done <= tx_done_next;
      
      // Update bit_duration when division is done
      if (div_done) begin
        bit_duration <= (quotient == 16'd0) ? 16'd5208 : quotient;
      end
      
      case (state)
        IDLE: begin
          tx_out_next <= 1'b1;
          tx_done_next <= 1'b0;
          if (tx_start) begin
            state <= START;
            tx_reg <= tx_data;
            baud_counter <= 0;
          end
        end
        START: begin
          tx_out_next <= 1'b0;
          baud_counter <= baud_counter + 1;
          if (baud_count_expired) begin
            baud_counter <= 0;
            state <= DATA;
            bit_idx <= 0;
          end
        end
        DATA: begin
          tx_out_next <= tx_reg[bit_idx];
          baud_counter <= baud_counter + 1;
          if (baud_count_expired) begin
            baud_counter <= 0;
            if (bit_idx_complete) state <= STOP;
            else bit_idx <= bit_idx + 1;
          end
        end
        STOP: begin
          tx_out_next <= 1'b1;
          baud_counter <= baud_counter + 1;
          if (baud_count_expired) begin
            state <= IDLE;
            tx_done_next <= 1'b1;
          end
        end
      endcase
    end
  end
endmodule
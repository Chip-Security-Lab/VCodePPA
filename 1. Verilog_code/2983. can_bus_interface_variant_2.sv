//SystemVerilog
module can_bus_interface #(
  parameter CLK_FREQ_MHZ = 40,
  parameter CAN_BITRATE_KBPS = 1000
)(
  input wire clk, rst_n,
  input wire tx_data_bit,
  output reg rx_data_bit,
  input wire can_rx,
  output reg can_tx,
  output reg bit_sample_point
);
  // SRT Divider implementation to replace direct division
  wire [15:0] divider_result;
  
  srt_divider #(
    .WIDTH(16)
  ) bit_timing_divider (
    .clk(clk),
    .rst_n(rst_n),
    .dividend(CLK_FREQ_MHZ * 1000),
    .divisor(CAN_BITRATE_KBPS),
    .quotient(divider_result),
    .start(1'b1)
  );
  
  wire [15:0] DIVIDER = divider_result;
  wire [15:0] SAMPLE_POINT = {2'b0, DIVIDER[15:2]} + {1'b0, DIVIDER[15:1]}; // Optimized: DIVIDER*3/4
  
  reg [15:0] counter;
  wire counter_max = (counter == DIVIDER-1);
  wire sample_point = (counter == SAMPLE_POINT);
  wire bit_start = (counter == 0);
  
  always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
      counter <= 16'h0;
      bit_sample_point <= 1'b0;
      can_tx <= 1'b1; // Recessive state
      rx_data_bit <= 1'b1;
    end else begin
      // Counter logic
      counter <= counter_max ? 16'h0 : counter + 16'h1;
      
      // Sampling signals
      bit_sample_point <= sample_point;
      
      // Transmission logic - only update when needed
      if (bit_start) begin
        can_tx <= tx_data_bit;
      end
      
      // Reception logic - only sample at the proper point
      if (sample_point) begin
        rx_data_bit <= can_rx;
      end
    end
  end
endmodule

// SRT Divider module implementation
module srt_divider #(
  parameter WIDTH = 16
)(
  input wire clk,
  input wire rst_n,
  input wire [WIDTH-1:0] dividend,
  input wire [WIDTH-1:0] divisor,
  output reg [WIDTH-1:0] quotient,
  input wire start
);
  // Internal signals
  reg [WIDTH-1:0] Q;          // Quotient
  reg [WIDTH:0] A;            // Accumulator
  reg [WIDTH-1:0] M;          // Divisor
  reg [4:0] count;            // Iteration counter
  reg busy;                   // Operation in progress flag
  reg [1:0] state;            // FSM state
  
  // States
  localparam IDLE = 2'b00;
  localparam SETUP = 2'b01;
  localparam COMPUTE = 2'b10;
  localparam COMPLETE = 2'b11;
  
  // SRT Division core algorithm
  always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
      state <= IDLE;
      busy <= 1'b0;
      quotient <= {WIDTH{1'b0}};
      Q <= {WIDTH{1'b0}};
      A <= {(WIDTH+1){1'b0}};
      M <= {WIDTH{1'b0}};
      count <= 5'b0;
    end
    else begin
      case (state)
        IDLE: begin
          if (start) begin
            state <= SETUP;
            busy <= 1'b1;
          end
        end
        
        SETUP: begin
          // Initialize
          A <= {1'b0, dividend};
          M <= divisor;
          Q <= {WIDTH{1'b0}};
          count <= WIDTH;
          state <= COMPUTE;
        end
        
        COMPUTE: begin
          if (count > 0) begin
            // Left shift A and Q
            A <= {A[WIDTH-1:0], Q[WIDTH-1]};
            Q <= {Q[WIDTH-2:0], 1'b0};
            
            // SRT algorithm - compute +1, 0, or -1 quotient digit
            if (A[WIDTH] == 1'b1) begin
              // If A is negative, add M
              A <= A + {1'b0, M};
              Q[0] <= 1'b0;
            end
            else begin
              // If A is non-negative, subtract M
              A <= A - {1'b0, M};
              Q[0] <= 1'b1;
            end
            
            // In next cycle, restore if needed
            if ((A[WIDTH] == 1'b1 && Q[0] == 1'b1) || 
                (A[WIDTH] == 1'b0 && Q[0] == 1'b0)) begin
              if (A[WIDTH] == 1'b1) begin
                A <= A + {1'b0, M};
              end
              else begin
                A <= A - {1'b0, M};
              end
              Q[0] <= ~Q[0];
            end
            
            count <= count - 1;
          end
          else begin
            state <= COMPLETE;
          end
        end
        
        COMPLETE: begin
          quotient <= Q;
          busy <= 1'b0;
          state <= IDLE;
        end
      endcase
    end
  end
endmodule
//SystemVerilog
module uart_oversampling #(parameter CLK_FREQ = 48_000_000, BAUD = 115200) (
  input wire clk, rst_n,
  input wire rx,
  output reg [7:0] rx_data,
  output reg rx_valid
);
  // Calculate oversampling rate (16x standard)
  localparam OSR = 16;
  localparam CLKS_PER_BIT = CLK_FREQ / (BAUD * OSR);
  
  // State machine definitions
  localparam IDLE = 2'b00, START = 2'b01, DATA = 2'b10, STOP = 2'b11;
  reg [1:0] state;
  
  // Counters - optimized bit widths
  reg [$clog2(CLKS_PER_BIT)-1:0] clk_counter;
  reg [3:0] os_counter; // Oversampling counter
  reg [2:0] bit_counter;
  
  // Sample registers
  reg [7:0] shift_reg;
  reg [OSR-1:0] sample_window;
  
  // Majority voting logic - pre-computed
  wire bit_value;
  wire [4:0] ones_count;
  
  // Optimized state transition and counter comparison logic
  wire clk_cycle_end = (clk_counter == CLKS_PER_BIT-1);
  wire mid_start_bit = (os_counter == OSR/2);
  wire sample_complete = (os_counter == OSR-1);
  wire byte_complete = (bit_counter == 7);

  // Instantiate Han-Carlson adder for ones counting
  han_carlson_popcount #(
    .WIDTH(OSR)
  ) ones_counter (
    .data(sample_window),
    .count(ones_count)
  );
  
  // Majority vote result
  assign bit_value = (ones_count > (OSR/2));
  
  always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
      state <= IDLE;
      clk_counter <= 0;
      os_counter <= 0;
      bit_counter <= 0;
      shift_reg <= 0;
      rx_data <= 0;
      rx_valid <= 0;
      sample_window <= 0;
    end else begin
      // Default assignments
      rx_valid <= 0;
      
      // Always increment clock counter unless reset
      if (clk_cycle_end) begin
        clk_counter <= 0;
        
        case (state)
          IDLE: begin
            if (rx == 0) begin // Start bit detected
              state <= START;
              os_counter <= 0;
            end
          end
          
          START: begin
            if (mid_start_bit) begin
              state <= DATA;
              bit_counter <= 0;
              os_counter <= 0;
              sample_window <= 0;
            end else begin
              os_counter <= os_counter + 1;
            end
          end
          
          DATA: begin
            // Fill sample window continuously
            sample_window <= {sample_window[OSR-2:0], rx};
            
            if (sample_complete) begin
              shift_reg[bit_counter] <= bit_value;
              os_counter <= 0;
              
              if (byte_complete) begin
                state <= STOP;
              end else begin
                bit_counter <= bit_counter + 1;
              end
            end else begin
              os_counter <= os_counter + 1;
            end
          end
          
          STOP: begin
            if (mid_start_bit) begin
              state <= IDLE;
              rx_data <= shift_reg;
              rx_valid <= 1;
            end else begin
              os_counter <= os_counter + 1;
            end
          end
        endcase
      end else begin
        clk_counter <= clk_counter + 1;
      end
    end
  end
endmodule

//SystemVerilog
module han_carlson_popcount #(
  parameter WIDTH = 16  // Default width is 16 bits
) (
  input wire [WIDTH-1:0] data,
  output wire [$clog2(WIDTH+1)-1:0] count
);
  // Calculate required adder width (number of full pairs)
  localparam ADDER_WIDTH = WIDTH / 2 + (WIDTH % 2);
  
  // Han-Carlson adder signals
  wire [ADDER_WIDTH-1:0] p, g; // propagate and generate signals
  wire [ADDER_WIDTH-1:0] p_stage1, g_stage1; // stage 1 signals
  wire [ADDER_WIDTH-1:0] p_stage2, g_stage2; // stage 2 signals
  wire [ADDER_WIDTH-1:0] p_stage3, g_stage3; // stage 3 signals
  wire [ADDER_WIDTH-1:0] sum; // final sum output
  wire c_out; // carry out
  
  // Handle the case when WIDTH is odd
  wire [2*ADDER_WIDTH-1:0] padded_data;
  assign padded_data = {{(2*ADDER_WIDTH-WIDTH){1'b0}}, data};

  // Generate initial propagate and generate signals
  // Group sample window bits in pairs for initial P and G generation
  genvar i;
  generate
    for (i = 0; i < ADDER_WIDTH; i = i + 1) begin : gen_init_pg
      assign p[i] = padded_data[i*2] | padded_data[i*2+1];
      assign g[i] = padded_data[i*2] & padded_data[i*2+1];
    end
  endgenerate

  // Han-Carlson Adder - Stage 1 (Even indices)
  generate
    for (i = 0; i < ADDER_WIDTH; i = i + 2) begin : gen_stage1_even
      assign p_stage1[i] = p[i];
      assign g_stage1[i] = g[i];
    end
  endgenerate

  // Han-Carlson Adder - Stage 1 (Odd indices)
  generate
    for (i = 1; i < ADDER_WIDTH; i = i + 2) begin : gen_stage1_odd
      assign p_stage1[i] = p[i] & p[i-1];
      assign g_stage1[i] = g[i] | (p[i] & g[i-1]);
    end
  endgenerate

  // Han-Carlson Adder - Stage 2 (Even indices)
  generate
    for (i = 2; i < ADDER_WIDTH; i = i + 2) begin : gen_stage2_even
      assign p_stage2[i] = p_stage1[i] & p_stage1[i-1];
      assign g_stage2[i] = g_stage1[i] | (p_stage1[i] & g_stage1[i-1]);
    end
  endgenerate

  // Han-Carlson Adder - Stage 2 (Odd indices remain unchanged)
  generate
    for (i = 1; i < ADDER_WIDTH; i = i + 2) begin : gen_stage2_odd
      assign p_stage2[i] = p_stage1[i];
      assign g_stage2[i] = g_stage1[i];
    end
  endgenerate
  
  // Handle index 0
  assign p_stage2[0] = p_stage1[0];
  assign g_stage2[0] = g_stage1[0];

  // Han-Carlson Adder - Stage 3 (Odd indices)
  generate
    for (i = 1; i < ADDER_WIDTH; i = i + 2) begin : gen_stage3_odd
      assign p_stage3[i] = p_stage2[i] & p_stage2[i-1];
      assign g_stage3[i] = g_stage2[i] | (p_stage2[i] & g_stage2[i-1]);
    end
  endgenerate

  // Han-Carlson Adder - Stage 3 (Even indices remain unchanged)
  generate
    for (i = 0; i < ADDER_WIDTH; i = i + 2) begin : gen_stage3_even
      assign p_stage3[i] = p_stage2[i];
      assign g_stage3[i] = g_stage2[i];
    end
  endgenerate

  // Sum computation
  assign sum[0] = p[0];
  generate
    for (i = 1; i < ADDER_WIDTH; i = i + 1) begin : gen_sum
      assign sum[i] = p[i] ^ g_stage3[i-1];
    end
  endgenerate
  
  // Carry out computation
  assign c_out = (ADDER_WIDTH > 0) ? g_stage3[ADDER_WIDTH-1] : 1'b0;

  // Calculate ones count using Han-Carlson adder result
  assign count = {c_out, sum};
endmodule
//SystemVerilog
module kogge_stone_adder_32bit (
  input wire [31:0] a,
  input wire [31:0] b,
  input wire cin,
  output wire [31:0] sum,
  output wire cout
);

  // Generate and propagate signals
  wire [31:0] g, p;
  
  // First level - generate and propagate
  genvar i;
  generate
    for (i = 0; i < 32; i = i + 1) begin : gen_prop
      assign g[i] = a[i] & b[i];
      assign p[i] = a[i] ^ b[i];
    end
  endgenerate

  // Optimized carry computation using parallel prefix
  wire [31:0] g_1, p_1, g_2, p_2, g_4, p_4, g_8, p_8, g_16, p_16;
  
  // Level 1 (1-bit grouping)
  assign g_1[0] = g[0];
  assign p_1[0] = p[0];
  genvar j;
  generate
    for (j = 1; j < 32; j = j + 1) begin : level1
      assign g_1[j] = g[j] | (p[j] & g[j-1]);
      assign p_1[j] = p[j] & p[j-1];
    end
  endgenerate

  // Level 2 (2-bit grouping)
  assign g_2[1:0] = g_1[1:0];
  assign p_2[1:0] = p_1[1:0];
  genvar k;
  generate
    for (k = 2; k < 32; k = k + 1) begin : level2
      assign g_2[k] = g_1[k] | (p_1[k] & g_1[k-2]);
      assign p_2[k] = p_1[k] & p_1[k-2];
    end
  endgenerate

  // Level 3 (4-bit grouping)
  assign g_4[3:0] = g_2[3:0];
  assign p_4[3:0] = p_2[3:0];
  genvar l;
  generate
    for (l = 4; l < 32; l = l + 1) begin : level4
      assign g_4[l] = g_2[l] | (p_2[l] & g_2[l-4]);
      assign p_4[l] = p_2[l] & p_2[l-4];
    end
  endgenerate

  // Level 4 (8-bit grouping)
  assign g_8[7:0] = g_4[7:0];
  assign p_8[7:0] = p_4[7:0];
  genvar m;
  generate
    for (m = 8; m < 32; m = m + 1) begin : level8
      assign g_8[m] = g_4[m] | (p_4[m] & g_4[m-8]);
      assign p_8[m] = p_4[m] & p_4[m-8];
    end
  endgenerate

  // Level 5 (16-bit grouping)
  assign g_16[15:0] = g_8[15:0];
  assign p_16[15:0] = p_8[15:0];
  genvar n;
  generate
    for (n = 16; n < 32; n = n + 1) begin : level16
      assign g_16[n] = g_8[n] | (p_8[n] & g_8[n-16]);
      assign p_16[n] = p_8[n] & p_8[n-16];
    end
  endgenerate

  // Final carry computation
  wire [32:0] carry;
  assign carry[0] = cin;
  genvar o;
  generate
    for (o = 1; o < 33; o = o + 1) begin : final_carry
      assign carry[o] = g_16[o-1] | (p_16[o-1] & carry[o-1]);
    end
  endgenerate

  // Sum computation
  assign sum = p ^ {carry[31:0]};
  assign cout = carry[32];

endmodule

module mipi_soundwire_formatter #(parameter CHANNELS = 2) (
  input wire clk, reset_n,
  input wire [15:0] pcm_data_in [0:CHANNELS-1],
  input wire data_valid,
  output reg [31:0] soundwire_frame,
  output reg frame_valid
);

  localparam IDLE = 2'b00, HEADER = 2'b01, PAYLOAD = 2'b10, TRAILER = 2'b11;
  
  reg [1:0] state;
  reg [3:0] channel_cnt;
  reg [7:0] frame_counter;
  
  // Optimized adder signals
  wire [31:0] adder_a, adder_b;
  wire [31:0] adder_sum;
  wire adder_cout;
  
  // Direct assignment without intermediate signals
  assign adder_a = {16'h0000, pcm_data_in[channel_cnt]};
  assign adder_b = 32'h00000000;
  
  // Instantiate optimized Kogge-Stone adder
  kogge_stone_adder_32bit adder_inst (
    .a(adder_a),
    .b(adder_b),
    .cin(1'b0),
    .sum(adder_sum),
    .cout(adder_cout)
  );
  
  always @(posedge clk or negedge reset_n) begin
    if (!reset_n) begin
      state <= IDLE;
      channel_cnt <= 4'd0;
      frame_counter <= 8'd0;
      frame_valid <= 1'b0;
    end else case (state)
      IDLE: if (data_valid) begin
        state <= HEADER;
        channel_cnt <= 4'd0;
        soundwire_frame <= {8'hA5, 8'h00, 8'h00, 8'h00};
        frame_valid <= 1'b1;
      end
      HEADER: begin
        state <= PAYLOAD;
        frame_valid <= 1'b0;
      end
      PAYLOAD: begin
        if (channel_cnt < CHANNELS) begin
          soundwire_frame <= adder_sum;
          channel_cnt <= channel_cnt + 1'b1;
          frame_valid <= 1'b1;
        end else state <= TRAILER;
      end
      TRAILER: begin
        soundwire_frame <= {24'h000000, frame_counter};
        frame_counter <= frame_counter + 1'b1;
        frame_valid <= 1'b1;
        state <= IDLE;
      end
    endcase
  end
endmodule
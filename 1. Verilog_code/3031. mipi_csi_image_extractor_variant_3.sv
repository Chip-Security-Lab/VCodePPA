//SystemVerilog
module mipi_csi_image_extractor (
  input wire clk, reset_n,
  input wire [31:0] packet_data,
  input wire packet_valid, packet_start, packet_end,
  input wire [7:0] packet_type,
  output reg [15:0] pixel_data,
  output reg pixel_valid,
  output reg frame_start, frame_end, line_start, line_end
);

  localparam FRAME_START = 8'h00, LINE_START = 8'h01;
  localparam FRAME_END = 8'h02, LINE_END = 8'h03, RAW_10 = 8'h2B;
  
  reg [2:0] state;
  reg [31:0] data_buffer;
  reg [1:0] pixel_count;
  
  // Optimized carry lookahead adder
  wire [31:0] sum;
  wire [31:0] carry;
  wire [31:0] prop;
  wire [31:0] gen;
  
  // Simplified generate and propagate signals
  assign gen = data_buffer & packet_data;
  assign prop = data_buffer ^ packet_data;
  
  // Optimized carry lookahead logic using 4-bit blocks
  assign carry[0] = 1'b0;
  
  genvar i;
  generate
    for(i=0; i<32; i=i+4) begin : carry_block
      wire [3:0] block_gen = gen[i+:4];
      wire [3:0] block_prop = prop[i+:4];
      wire block_carry = (i == 0) ? 1'b0 : carry[i-1];
      
      assign carry[i] = block_gen[0] | (block_prop[0] & block_carry);
      assign carry[i+1] = block_gen[1] | (block_prop[1] & block_gen[0]) | 
                         (block_prop[1] & block_prop[0] & block_carry);
      assign carry[i+2] = block_gen[2] | (block_prop[2] & block_gen[1]) | 
                         (block_prop[2] & block_prop[1] & block_gen[0]) |
                         (block_prop[2] & block_prop[1] & block_prop[0] & block_carry);
      assign carry[i+3] = block_gen[3] | (block_prop[3] & block_gen[2]) | 
                         (block_prop[3] & block_prop[2] & block_gen[1]) |
                         (block_prop[3] & block_prop[2] & block_prop[1] & block_gen[0]) |
                         (block_prop[3] & block_prop[2] & block_prop[1] & block_prop[0] & block_carry);
    end
  endgenerate
  
  // Optimized sum calculation
  assign sum = prop ^ carry;
  
  // Optimized state machine
  always @(posedge clk or negedge reset_n) begin
    if (!reset_n) begin
      state <= 3'd0;
      pixel_valid <= 1'b0;
      frame_start <= 1'b0;
      frame_end <= 1'b0;
      line_start <= 1'b0;
      line_end <= 1'b0;
    end else begin
      pixel_valid <= 1'b0;
      frame_start <= 1'b0;
      frame_end <= 1'b0;
      line_start <= 1'b0;
      line_end <= 1'b0;
      
      if (packet_valid) begin
        if (packet_start) begin
          frame_start <= (packet_type == FRAME_START);
          line_start <= (packet_type == LINE_START);
        end
        else if (packet_end) begin
          frame_end <= (packet_type == FRAME_END);
          line_end <= (packet_type == LINE_END);
        end
        else if (packet_type == RAW_10) begin
          data_buffer <= sum;
          pixel_count <= 2'd0;
          state <= 3'd1;
        end
      end
      
      if (state == 3'd1) begin
        case (pixel_count)
          2'd0: pixel_data <= {data_buffer[9:0], 6'b0};
          2'd1: pixel_data <= {data_buffer[19:10], 6'b0};
          2'd2: pixel_data <= {data_buffer[29:20], 6'b0};
          2'd3: pixel_data <= {data_buffer[31:30], 8'b0, 6'b0};
        endcase
        pixel_valid <= 1'b1;
        pixel_count <= pixel_count + 1'b1;
        if (pixel_count == 2'd3) state <= 3'd0;
      end
    end
  end
endmodule
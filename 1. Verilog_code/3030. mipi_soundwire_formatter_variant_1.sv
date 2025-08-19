//SystemVerilog
module mipi_soundwire_formatter #(parameter CHANNELS = 2) (
  input wire clk, reset_n,
  input wire [15:0] pcm_data_in [0:CHANNELS-1],
  input wire data_valid,
  output reg [31:0] soundwire_frame,
  output reg frame_valid
);

  localparam IDLE = 2'b00, HEADER = 2'b01, PAYLOAD = 2'b10, TRAILER = 2'b11;
  
  // Pipeline stage 1 registers
  reg [1:0] state_stage1;
  reg [3:0] channel_cnt_stage1;
  reg [7:0] frame_counter_stage1;
  reg data_valid_stage1;
  reg [15:0] pcm_data_stage1 [0:CHANNELS-1];
  
  // Pipeline stage 2 registers  
  reg [1:0] state_stage2;
  reg [3:0] channel_cnt_stage2;
  reg [7:0] frame_counter_stage2;
  reg frame_valid_stage2;
  reg [31:0] soundwire_frame_stage2;
  
  // Pipeline stage 3 registers
  reg [1:0] state_stage3;
  reg [3:0] channel_cnt_stage3;
  reg [7:0] frame_counter_stage3;
  reg frame_valid_stage3;
  reg [31:0] soundwire_frame_stage3;

  // Stage 1: Input sampling
  always @(posedge clk or negedge reset_n) begin
    if (!reset_n) begin
      data_valid_stage1 <= 1'b0;
    end else begin
      data_valid_stage1 <= data_valid;
      for (int i=0; i<CHANNELS; i=i+1)
        pcm_data_stage1[i] <= pcm_data_in[i];
    end
  end

  // Stage 1: State machine
  always @(posedge clk or negedge reset_n) begin
    if (!reset_n) begin
      state_stage1 <= IDLE;
      channel_cnt_stage1 <= 4'd0;
      frame_counter_stage1 <= 8'd0;
    end else begin
      case (state_stage1)
        IDLE: if (data_valid) begin
          state_stage1 <= HEADER;
          channel_cnt_stage1 <= 4'd0;
        end
        HEADER: state_stage1 <= PAYLOAD;
        PAYLOAD: begin
          if (channel_cnt_stage1 < CHANNELS) begin
            channel_cnt_stage1 <= channel_cnt_stage1 + 1'b1;
          end else begin
            state_stage1 <= TRAILER;
          end
        end
        TRAILER: begin
          frame_counter_stage1 <= frame_counter_stage1 + 1'b1;
          state_stage1 <= IDLE;
        end
      endcase
    end
  end

  // Stage 2: State and counter pipeline
  always @(posedge clk or negedge reset_n) begin
    if (!reset_n) begin
      state_stage2 <= IDLE;
      channel_cnt_stage2 <= 4'd0;
      frame_counter_stage2 <= 8'd0;
    end else begin
      state_stage2 <= state_stage1;
      channel_cnt_stage2 <= channel_cnt_stage1;
      frame_counter_stage2 <= frame_counter_stage1;
    end
  end

  // Stage 2: Frame generation
  always @(posedge clk or negedge reset_n) begin
    if (!reset_n) begin
      frame_valid_stage2 <= 1'b0;
      soundwire_frame_stage2 <= 32'd0;
    end else begin
      case (state_stage1)
        IDLE: frame_valid_stage2 <= 1'b0;
        HEADER: begin
          soundwire_frame_stage2 <= {8'hA5, 8'h00, 8'h00, 8'h00};
          frame_valid_stage2 <= 1'b1;
        end
        PAYLOAD: begin
          if (channel_cnt_stage1 < CHANNELS) begin
            soundwire_frame_stage2 <= {pcm_data_stage1[channel_cnt_stage1], 16'h0000};
            frame_valid_stage2 <= 1'b1;
          end else begin
            frame_valid_stage2 <= 1'b0;
          end
        end
        TRAILER: begin
          soundwire_frame_stage2 <= {24'h000000, frame_counter_stage1};
          frame_valid_stage2 <= 1'b1;
        end
      endcase
    end
  end

  // Stage 3: Output pipeline
  always @(posedge clk or negedge reset_n) begin
    if (!reset_n) begin
      state_stage3 <= IDLE;
      channel_cnt_stage3 <= 4'd0;
      frame_counter_stage3 <= 8'd0;
      frame_valid <= 1'b0;
      soundwire_frame <= 32'd0;
    end else begin
      state_stage3 <= state_stage2;
      channel_cnt_stage3 <= channel_cnt_stage2;
      frame_counter_stage3 <= frame_counter_stage2;
      frame_valid <= frame_valid_stage2;
      soundwire_frame <= soundwire_frame_stage2;
    end
  end

endmodule
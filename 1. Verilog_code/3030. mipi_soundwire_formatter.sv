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
          soundwire_frame <= {pcm_data_in[channel_cnt], 16'h0000};
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
//SystemVerilog
module mipi_slimbus_interface (
  input wire clk, reset_n,
  input wire data_in, clock_in,
  input wire [7:0] device_id,
  output reg data_out, frame_sync,
  output reg [31:0] received_data,
  output reg data_valid
);

  localparam SYNC = 2'b00, HEADER = 2'b01, DATA = 2'b10, CRC = 2'b11;
  
  // Pipeline stage 1: Sync and Frame Counter
  reg [1:0] state_stage1;
  reg [9:0] frame_counter_stage1;
  reg frame_sync_stage1;
  
  // Pipeline stage 2: Header Processing
  reg [1:0] state_stage2;
  reg [7:0] bit_counter_stage2;
  reg [7:0] header_data_stage2;
  reg header_valid_stage2;
  
  // Pipeline stage 3: Data Processing
  reg [1:0] state_stage3;
  reg [7:0] bit_counter_stage3;
  reg [31:0] data_buffer_stage3;
  reg data_valid_stage3;
  
  // Pipeline stage 4: CRC and Output
  reg [1:0] state_stage4;
  reg [7:0] bit_counter_stage4;
  reg [31:0] received_data_stage4;
  reg data_valid_stage4;
  
  // Pipeline control signals
  reg valid_stage1, valid_stage2, valid_stage3, valid_stage4;
  
  // Stage 1: Sync Detection
  always @(posedge clock_in or negedge reset_n) begin
    if (!reset_n) begin
      state_stage1 <= SYNC;
      frame_counter_stage1 <= 10'd0;
      frame_sync_stage1 <= 1'b0;
      valid_stage1 <= 1'b0;
    end else begin
      valid_stage1 <= 1'b1;
      if (data_in && frame_counter_stage1 == 10'd511) begin
        state_stage1 <= HEADER;
        frame_sync_stage1 <= 1'b1;
      end else begin
        frame_sync_stage1 <= 1'b0;
      end
      frame_counter_stage1 <= (frame_counter_stage1 == 10'd511) ? 10'd0 : frame_counter_stage1 + 1'b1;
    end
  end
  
  // Stage 2: Header Processing
  always @(posedge clock_in or negedge reset_n) begin
    if (!reset_n) begin
      state_stage2 <= SYNC;
      bit_counter_stage2 <= 8'd0;
      header_data_stage2 <= 8'd0;
      header_valid_stage2 <= 1'b0;
      valid_stage2 <= 1'b0;
    end else if (valid_stage1) begin
      valid_stage2 <= 1'b1;
      state_stage2 <= state_stage1;
      
      if (state_stage1 == HEADER) begin
        if (bit_counter_stage2 < 8'd15) begin
          bit_counter_stage2 <= bit_counter_stage2 + 1'b1;
          if (bit_counter_stage2 < 8) begin
            header_data_stage2 <= {header_data_stage2[6:0], data_in};
            if (bit_counter_stage2 == 7 && header_data_stage2 != device_id) begin
              header_valid_stage2 <= 1'b0;
            end else begin
              header_valid_stage2 <= 1'b1;
            end
          end
        end else begin
          bit_counter_stage2 <= 8'd0;
        end
      end
    end
  end
  
  // Stage 3: Data Processing
  always @(posedge clock_in or negedge reset_n) begin
    if (!reset_n) begin
      state_stage3 <= SYNC;
      bit_counter_stage3 <= 8'd0;
      data_buffer_stage3 <= 32'd0;
      data_valid_stage3 <= 1'b0;
      valid_stage3 <= 1'b0;
    end else if (valid_stage2) begin
      valid_stage3 <= 1'b1;
      state_stage3 <= state_stage2;
      
      if (state_stage2 == DATA && header_valid_stage2) begin
        if (bit_counter_stage3 < 8'd31) begin
          bit_counter_stage3 <= bit_counter_stage3 + 1'b1;
          data_buffer_stage3 <= {data_buffer_stage3[30:0], data_in};
        end else begin
          bit_counter_stage3 <= 8'd0;
          data_valid_stage3 <= 1'b1;
        end
      end
    end
  end
  
  // Stage 4: CRC and Output
  always @(posedge clock_in or negedge reset_n) begin
    if (!reset_n) begin
      state_stage4 <= SYNC;
      bit_counter_stage4 <= 8'd0;
      received_data_stage4 <= 32'd0;
      data_valid_stage4 <= 1'b0;
      valid_stage4 <= 1'b0;
    end else if (valid_stage3) begin
      valid_stage4 <= 1'b1;
      state_stage4 <= state_stage3;
      
      if (state_stage3 == CRC && data_valid_stage3) begin
        if (bit_counter_stage4 < 8'd7) begin
          bit_counter_stage4 <= bit_counter_stage4 + 1'b1;
        end else begin
          bit_counter_stage4 <= 8'd0;
          received_data_stage4 <= data_buffer_stage3;
          data_valid_stage4 <= 1'b1;
        end
      end
    end
  end
  
  // Output assignments
  always @(posedge clk or negedge reset_n) begin
    if (!reset_n) begin
      data_out <= 1'b0;
      frame_sync <= 1'b0;
      received_data <= 32'd0;
      data_valid <= 1'b0;
    end else begin
      frame_sync <= frame_sync_stage1;
      received_data <= received_data_stage4;
      data_valid <= data_valid_stage4;
      if (state_stage3 == DATA) begin
        data_out <= data_buffer_stage3[31];
      end else begin
        data_out <= 1'b0;
      end
    end
  end
endmodule
//SystemVerilog
module can_bit_stuffer(
  input wire clk, rst_n,
  input wire data_in, data_valid,
  input wire stuffing_active,
  output reg data_out,
  output reg data_out_valid,
  output reg stuff_error
);
  // Pipeline stage 1 registers
  reg data_in_p1;
  reg data_valid_p1;
  reg stuffing_active_p1;
  
  // Pipeline stage 2 registers
  reg data_in_p2;
  reg data_valid_p2;
  reg stuffing_active_p2;
  reg last_bit_p2;
  reg [2:0] same_bit_count_p2;
  
  // Pipeline stage 2.5 registers - Added to break critical path
  reg bit_match_p2_5;
  reg data_in_p2_5;
  reg data_valid_p2_5;
  reg stuffing_active_p2_5;
  reg last_bit_p2_5;
  reg [2:0] same_bit_count_p2_5;
  
  // Pipeline stage 3 registers
  reg need_stuff_bit;
  reg data_to_output;
  reg output_valid;
  
  // Main state registers
  reg [2:0] same_bit_count;
  reg last_bit;
  reg stuffed_bit;
  
  // Stage 1: Register inputs and begin processing
  always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
      data_in_p1 <= 0;
      data_valid_p1 <= 0;
      stuffing_active_p1 <= 0;
    end else begin
      data_in_p1 <= data_in;
      data_valid_p1 <= data_valid;
      stuffing_active_p1 <= stuffing_active;
    end
  end
  
  // Stage 2: Bit matching calculation and prepare for decision
  always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
      data_in_p2 <= 0;
      data_valid_p2 <= 0;
      stuffing_active_p2 <= 0;
      last_bit_p2 <= 0;
      same_bit_count_p2 <= 0;
      
      // Reset additional pipeline stage
      bit_match_p2_5 <= 0;
      data_in_p2_5 <= 0;
      data_valid_p2_5 <= 0;
      stuffing_active_p2_5 <= 0;
      last_bit_p2_5 <= 0;
      same_bit_count_p2_5 <= 0;
    end else begin
      data_in_p2 <= data_in_p1;
      data_valid_p2 <= data_valid_p1;
      stuffing_active_p2 <= stuffing_active_p1;
      last_bit_p2 <= last_bit;
      same_bit_count_p2 <= same_bit_count;
      
      // Add pipeline stage for bit_match calculation and forwarding data
      bit_match_p2_5 <= (data_in_p2 == last_bit_p2);
      data_in_p2_5 <= data_in_p2;
      data_valid_p2_5 <= data_valid_p2;
      stuffing_active_p2_5 <= stuffing_active_p2;
      last_bit_p2_5 <= last_bit_p2;
      same_bit_count_p2_5 <= same_bit_count_p2;
    end
  end
  
  // Stage 3: Make stuffing decision and prepare output
  // Now uses pipelined bit_match signal
  always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
      need_stuff_bit <= 0;
      data_to_output <= 0;
      output_valid <= 0;
    end else begin
      if (data_valid_p2_5 && stuffing_active_p2_5) begin
        // Check if we need to insert a stuff bit using pipelined bit_match
        need_stuff_bit <= (same_bit_count_p2_5 == 3'd4 && bit_match_p2_5);
        
        // Prepare output data
        data_to_output <= (same_bit_count_p2_5 == 3'd4 && bit_match_p2_5) ? ~last_bit_p2_5 : data_in_p2_5;
        output_valid <= 1'b1;
      end else begin
        need_stuff_bit <= 0;
        data_to_output <= data_in_p2_5;
        output_valid <= 0;
      end
    end
  end
  
  // Final stage: Update state and generate outputs
  always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
      same_bit_count <= 0;
      last_bit <= 0;
      stuffed_bit <= 0;
      data_out <= 1;
      data_out_valid <= 0;
      stuff_error <= 0;
    end else begin
      data_out_valid <= output_valid;
      data_out <= data_to_output;
      
      if (output_valid) begin
        if (need_stuff_bit) begin
          // Inserted stuff bit, reset counter
          same_bit_count <= 0;
          stuffed_bit <= 1;
        end else begin
          // Normal bit, update counter
          same_bit_count <= bit_match_p2_5 ? same_bit_count_p2_5 + 1'b1 : 3'b000;
          last_bit <= data_in_p2_5;
          stuffed_bit <= 0;
        end
      end
    end
  end
endmodule
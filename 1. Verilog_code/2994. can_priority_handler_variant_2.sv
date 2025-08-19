//SystemVerilog
module can_priority_handler #(
  parameter NUM_BUFFERS = 4
)(
  input wire clk, rst_n,
  input wire [10:0] msg_id [0:NUM_BUFFERS-1],
  input wire [NUM_BUFFERS-1:0] buffer_ready,
  output reg [NUM_BUFFERS-1:0] buffer_select,
  output reg transmit_request
);
  // Stage 1 registers - Finding minimum msg_id
  reg [10:0] highest_priority_id_stage1;
  reg [$clog2(NUM_BUFFERS)-1:0] highest_priority_idx_stage1;
  reg [NUM_BUFFERS-1:0] buffer_ready_stage1;
  reg stage1_valid;
  
  // Stage 2 registers - Output generation
  reg [10:0] highest_priority_id_stage2;
  reg [$clog2(NUM_BUFFERS)-1:0] highest_priority_idx_stage2;
  reg [NUM_BUFFERS-1:0] buffer_ready_stage2;
  reg stage2_valid;
  
  // Barrel shifter for buffer_select generation
  reg [NUM_BUFFERS-1:0] barrel_shifter_output;
  
  integer i;
  
  // Stage 1: Find highest priority message (lowest ID)
  always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
      highest_priority_id_stage1 <= 11'h7FF;
      highest_priority_idx_stage1 <= 0;
      buffer_ready_stage1 <= 0;
      stage1_valid <= 0;
    end else begin
      highest_priority_id_stage1 <= 11'h7FF; // Lowest priority
      highest_priority_idx_stage1 <= 0;
      buffer_ready_stage1 <= buffer_ready;
      stage1_valid <= 1;
      
      for (i = 0; i < NUM_BUFFERS; i = i + 1) begin
        if (buffer_ready[i] && msg_id[i] < highest_priority_id_stage1) begin
          highest_priority_id_stage1 <= msg_id[i];
          highest_priority_idx_stage1 <= i;
        end
      end
    end
  end
  
  // Barrel shifter implementation (replaces shift operation)
  always @(*) begin
    // Initialize with one-hot encoding at position 0
    barrel_shifter_output = {{(NUM_BUFFERS-1){1'b0}}, 1'b1};
    
    // MUX-based barrel shifter stages
    case (highest_priority_idx_stage2)
      // Generate case for each possible index value
      0: barrel_shifter_output = {{(NUM_BUFFERS-1){1'b0}}, 1'b1};
      1: barrel_shifter_output = {{(NUM_BUFFERS-2){1'b0}}, 1'b1, 1'b0};
      2: barrel_shifter_output = {{(NUM_BUFFERS-3){1'b0}}, 1'b1, 2'b0};
      3: barrel_shifter_output = {{(NUM_BUFFERS-4){1'b0}}, 1'b1, 3'b0};
      default: barrel_shifter_output = {{(NUM_BUFFERS-1){1'b0}}, 1'b1};
    endcase
  end
  
  // Stage 2: Generate outputs based on stage 1 results
  always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
      highest_priority_id_stage2 <= 11'h7FF;
      highest_priority_idx_stage2 <= 0;
      buffer_ready_stage2 <= 0;
      stage2_valid <= 0;
      buffer_select <= 0;
      transmit_request <= 0;
    end else begin
      // Pass along stage1 values to stage2
      highest_priority_id_stage2 <= highest_priority_id_stage1;
      highest_priority_idx_stage2 <= highest_priority_idx_stage1;
      buffer_ready_stage2 <= buffer_ready_stage1;
      stage2_valid <= stage1_valid;
      
      // Generate outputs only when stage2 is valid
      if (stage2_valid) begin
        // Use barrel shifter output instead of shift operation
        buffer_select <= (buffer_ready_stage2 != 0) ? barrel_shifter_output : 0;
        transmit_request <= (buffer_ready_stage2 != 0);
      end else begin
        buffer_select <= 0;
        transmit_request <= 0;
      end
    end
  end
endmodule
//SystemVerilog
module can_arbitration (
  // Clock and reset
  input  wire        clk,
  input  wire        rst_n,
  
  // AXI-Stream slave interface
  input  wire        s_axis_tvalid,
  output wire        s_axis_tready,
  input  wire [10:0] s_axis_tdata,   // tx_id
  input  wire        s_axis_tlast,   // tx_start
  
  // AXI-Stream master interface
  output wire        m_axis_tvalid,
  input  wire        m_axis_tready,
  output wire [1:0]  m_axis_tdata,   // {can_tx, arbitration_lost}
  output wire        m_axis_tlast,
  
  // CAN interface
  input  wire        can_rx
);

  // Stage 1: Input capture and preparation registers
  reg [10:0] shift_id_stage1;
  reg        in_arbitration_stage1;
  reg [3:0]  bit_count_stage1;
  reg        arbitration_lost_stage1;
  
  // Stage 2: Computation registers
  reg [10:0] shift_id_stage2;
  reg        in_arbitration_stage2;
  reg [3:0]  bit_count_stage2;
  reg        arbitration_lost_stage2;
  reg        can_tx_stage2;
  
  // Stage 3: Output and control registers
  reg        in_arbitration_stage3;
  reg        arbitration_lost_stage3;
  reg        can_tx_stage3;
  reg        process_done_stage3;
  reg [3:0]  bit_count_stage3;
  
  // Pipeline valid signals to track data through pipeline
  reg        pipeline_valid_s1;
  reg        pipeline_valid_s2;
  reg        pipeline_valid_s3;
  
  // AXI-Stream handshaking logic
  assign s_axis_tready = !in_arbitration_stage1 || process_done_stage3;
  assign m_axis_tvalid = in_arbitration_stage3 && pipeline_valid_s3;
  assign m_axis_tdata  = {can_tx_stage3, arbitration_lost_stage3};
  assign m_axis_tlast  = process_done_stage3;
  
  // Pipeline Stage 1: Input capture and initial processing
  always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
      shift_id_stage1 <= 11'b0;
      in_arbitration_stage1 <= 0;
      bit_count_stage1 <= 0;
      arbitration_lost_stage1 <= 0;
      pipeline_valid_s1 <= 0;
    end else begin
      pipeline_valid_s1 <= 1'b1;
      
      if (s_axis_tvalid && s_axis_tready && s_axis_tlast) begin
        // Start new arbitration
        shift_id_stage1 <= s_axis_tdata;
        in_arbitration_stage1 <= 1;
        bit_count_stage1 <= 0;
        arbitration_lost_stage1 <= 0;
      end else if (in_arbitration_stage1 && bit_count_stage1 < 11 && pipeline_valid_s3 && m_axis_tready) begin
        // Continue arbitration process
        shift_id_stage1 <= {shift_id_stage1[9:0], 1'b0};
        bit_count_stage1 <= bit_count_stage1 + 1;
      end else if (in_arbitration_stage1 && process_done_stage3 && pipeline_valid_s3 && m_axis_tready) begin
        // Reset after completion
        in_arbitration_stage1 <= 0;
      end
    end
  end
  
  // Pipeline Stage 2: Computation stage
  always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
      shift_id_stage2 <= 11'b0;
      in_arbitration_stage2 <= 0;
      bit_count_stage2 <= 0;
      arbitration_lost_stage2 <= 0;
      can_tx_stage2 <= 1;
      pipeline_valid_s2 <= 0;
    end else begin
      // Forward signals to next stage
      shift_id_stage2 <= shift_id_stage1;
      in_arbitration_stage2 <= in_arbitration_stage1;
      bit_count_stage2 <= bit_count_stage1;
      arbitration_lost_stage2 <= arbitration_lost_stage1;
      pipeline_valid_s2 <= pipeline_valid_s1;
      
      // Compute TX signal for current bit
      if (in_arbitration_stage1 && bit_count_stage1 < 11) begin
        can_tx_stage2 <= shift_id_stage1[10];
      end
    end
  end
  
  // Pipeline Stage 3: Arbitration loss detection and output control
  always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
      in_arbitration_stage3 <= 0;
      bit_count_stage3 <= 0;
      arbitration_lost_stage3 <= 0;
      can_tx_stage3 <= 1;
      process_done_stage3 <= 0;
      pipeline_valid_s3 <= 0;
    end else begin
      // Forward control signals
      in_arbitration_stage3 <= in_arbitration_stage2;
      bit_count_stage3 <= bit_count_stage2;
      can_tx_stage3 <= can_tx_stage2;
      pipeline_valid_s3 <= pipeline_valid_s2;
      
      // Default assignment
      process_done_stage3 <= 0;
      
      // Arbitration logic - detect arbitration loss
      if (in_arbitration_stage2 && bit_count_stage2 < 11 && pipeline_valid_s2) begin
        arbitration_lost_stage3 <= (can_rx == 0 && can_tx_stage2 == 1) ? 1'b1 : arbitration_lost_stage2;
        
        // Check if arbitration is complete
        if (bit_count_stage2 == 10) begin
          process_done_stage3 <= 1;
        end
      end else begin
        arbitration_lost_stage3 <= arbitration_lost_stage2;
      end
    end
  end

endmodule
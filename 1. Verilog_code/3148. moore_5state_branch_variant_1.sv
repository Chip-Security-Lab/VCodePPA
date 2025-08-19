//SystemVerilog
module moore_5state_branch_axi_stream (
  input  wire        aclk,
  input  wire        aresetn,
  
  // AXI-Stream Slave Interface
  input  wire        s_axis_tvalid,
  output wire        s_axis_tready,
  input  wire [0:0]  s_axis_tdata,  // sel input mapped to tdata
  
  // AXI-Stream Master Interface
  output wire        m_axis_tvalid,
  input  wire        m_axis_tready,
  output wire [1:0]  m_axis_tdata,  // {pathA, pathB} mapped to tdata
  output wire        m_axis_tlast
);

  // Internal signals
  reg [2:0] state, next_state;
  reg pathA_reg, pathB_reg;
  reg data_valid;
  reg input_valid_reg;
  reg input_data_reg;
  
  localparam S0=3'b000, S1=3'b001, S2=3'b010, S3=3'b011, S4=3'b100;
  
  // Input register stage
  always @(posedge aclk) begin
    if (!aresetn) begin
      input_valid_reg <= 1'b0;
      input_data_reg <= 1'b0;
    end else begin
      input_valid_reg <= s_axis_tvalid;
      input_data_reg <= s_axis_tdata[0];
    end
  end

  // AXI-Stream interface connections
  assign s_axis_tready = 1'b1;  // Always ready to accept new data
  assign m_axis_tvalid = data_valid;
  assign m_axis_tdata = {pathA_reg, pathB_reg};
  assign m_axis_tlast = (state == S3 || state == S4);  // Assert tlast at end of sequence
  
  // State register with synchronous reset (AXI-Stream uses active-low reset)
  always @(posedge aclk) begin
    if (!aresetn)
      state <= S0;
    else if (input_valid_reg || state != S0)  // Progress if valid data or already in sequence
      state <= next_state;
  end

  // Next state logic
  always @(*) begin
    case (state)
      S0: next_state = input_valid_reg ? (input_data_reg ? S1 : S2) : S0;
      S1: next_state = m_axis_tready ? S3 : S1;  // Wait for downstream ready
      S2: next_state = m_axis_tready ? S4 : S2;  // Wait for downstream ready
      S3: next_state = S0;
      S4: next_state = S0;
      default: next_state = S0;
    endcase
  end

  // Output logic
  always @(posedge aclk) begin
    if (!aresetn) begin
      pathA_reg <= 1'b0;
      pathB_reg <= 1'b0;
      data_valid <= 1'b0;
    end
    else begin
      // Default values
      pathA_reg <= 1'b0;
      pathB_reg <= 1'b0;
      
      case (state)
        S0: data_valid <= 1'b0;
        S1: begin
          pathA_reg <= 1'b1;
          data_valid <= 1'b1;
        end
        S2: begin
          pathB_reg <= 1'b1;
          data_valid <= 1'b1;
        end
        S3, S4: begin
          data_valid <= (m_axis_tready) ? 1'b0 : data_valid;  // Deassert valid after transfer
        end
        default: ;
      endcase
    end
  end

endmodule
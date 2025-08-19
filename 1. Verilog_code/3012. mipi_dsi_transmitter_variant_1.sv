//SystemVerilog
module mipi_dsi_transmitter_pipelined #(
  parameter DATA_LANES = 2,
  parameter BYTE_WIDTH = 8
)(
  input wire clk_hs, rst_n,
  input wire [BYTE_WIDTH-1:0] pixel_data, // Input data
  input wire start_tx, is_command,       // Control inputs
  output reg [DATA_LANES-1:0] hs_data_out, // Pipelined output
  output reg hs_clk_out,                 // Pipelined output
  output reg tx_done, busy               // Pipelined outputs
);
  localparam IDLE = 2'b00, SYNC = 2'b01, DATA = 2'b10, EOP = 2'b11;

  //------------------------------------------------------------------------
  // Stage 0: Input Registration, State Machine, Counter Logic
  // - Registers inputs.
  // - Contains state and counter registers.
  // - Calculates next state and counter value.
  // - Generates initial control signals and conditions.
  // - Generates valid signal for the next stage.
  //------------------------------------------------------------------------
  reg [1:0] state_s0;
  reg [5:0] counter_s0;
  reg is_command_s0_reg; // Registered input
  reg [BYTE_WIDTH-1:0] pixel_data_s0_reg; // Registered input

  // Combinatorial logic for next state and counter control (Stage 0 comb)
  wire load_counter_s0_comb = (state_s0 == SYNC);
  wire enable_counter_s0_comb = (state_s0 == DATA && counter_s0 < 6'd31); // Increment while counter < 31
  wire end_of_data_s0_comb = (counter_s0 == 6'd31); // End of data when counter reaches 31 (32nd cycle)

  wire [1:0] next_state_s0_comb;
  assign next_state_s0_comb =
    (state_s0 == IDLE && start_tx) ? SYNC :
    (state_s0 == SYNC)             ? DATA :
    (state_s0 == DATA && end_of_data_s0_comb) ? EOP :
    (state_s0 == EOP)              ? IDLE :
    state_s0; // Stay in current state if no transition condition met

  // Intermediate control/status signals derived from Stage 0 state (comb)
  wire is_busy_s0_comb = (state_s0 != IDLE);
  // tx_done_pulse high when state transitions to EOP or is in EOP
  // Let's make it high when state_s0 is EOP
  wire tx_done_pulse_s0_comb = (state_s0 == EOP);

  // Valid signal for Stage 1. High when the state machine is active (not in IDLE).
  wire valid_s0_comb = (state_s0 != IDLE);

  // Stage 0 Registers
  always @(posedge clk_hs) begin
    if (!rst_n) begin
      state_s0 <= IDLE;
      counter_s0 <= 6'b0;
      is_command_s0_reg <= 1'b0;
      pixel_data_s0_reg <= {BYTE_WIDTH{1'b0}};
    end else begin
      state_s0 <= next_state_s0_comb; // Update state
      is_command_s0_reg <= is_command; // Register input
      pixel_data_s0_reg <= pixel_data; // Register input

      if (load_counter_s0_comb) begin
        counter_s0 <= 6'b0; // Load 0
      end else if (enable_counter_s0_comb) begin
        counter_s0 <= counter_s0 + 1'b1; // Increment counter
      end
      // Counter holds value when enable_counter_s0_comb is false
    end
  end

  //------------------------------------------------------------------------
  // Stage 1: Register Stage 0 Outputs, Intermediate Data/Control Logic
  // - Registers state, counter, inputs, and S0 comb signals.
  // - Performs intermediate logic based on registered S0 values.
  // - Generates valid signal for the next stage.
  //------------------------------------------------------------------------
  reg [1:0] state_s1;
  reg [5:0] counter_s1;
  reg is_busy_s1;
  reg tx_done_pulse_s1;
  reg is_command_s1;
  reg [BYTE_WIDTH-1:0] pixel_data_s1;
  reg valid_s1; // Valid signal registered from S0

  // Stage 1 Registers (Registering outputs from Stage 0)
  always @(posedge clk_hs) begin
    if (!rst_n) begin
      state_s1 <= IDLE;
      counter_s1 <= 6'b0;
      is_busy_s1 <= 1'b0;
      tx_done_pulse_s1 <= 1'b0;
      is_command_s1 <= 1'b0;
      pixel_data_s1 <= {BYTE_WIDTH{1'b0}};
      valid_s1 <= 1'b0;
    end else begin
      // Register outputs from Stage 0 (either comb or reg)
      state_s1 <= state_s0; // Register state (S0 reg)
      counter_s1 <= counter_s0; // Register counter (S0 reg)
      is_busy_s1 <= is_busy_s0_comb; // Register S0 comb signal
      tx_done_pulse_s1 <= tx_done_pulse_s0_comb; // Register S0 comb signal
      is_command_s1 <= is_command_s0_reg; // Register S0 registered input
      pixel_data_s1 <= pixel_data_s0_reg; // Register S0 registered input
      valid_s1 <= valid_s0_comb; // Register S0 valid comb signal
    end
  end

  // Combinatorial logic for outputs based on Stage 1 registered values (Stage 1 comb)
  // This is where data formatting/processing would happen in a real design.
  // Placeholder logic: data is all 1s when valid, clock is high when valid.
  wire [DATA_LANES-1:0] hs_data_out_s1_comb;
  wire hs_clk_out_s1_comb;
  wire tx_done_s1_comb;
  wire busy_s1_comb;

  // Use valid_s1 to gate the combinatorial logic results
  assign hs_data_out_s1_comb = (valid_s1) ? {DATA_LANES{1'b1}} : {DATA_LANES{1'b0}}; // Example data
  assign hs_clk_out_s1_comb = valid_s1; // Clock active when valid
  assign tx_done_s1_comb = tx_done_pulse_s1; // Pass through registered S1 pulse
  assign busy_s1_comb = is_busy_s1; // Pass through registered S1 busy

  // Valid signal for Stage 2. Simply pass valid from Stage 1 registered value.
  wire valid_s1_to_s2 = valid_s1; // This signal goes into Stage 2 registers

  //------------------------------------------------------------------------
  // Stage 2: Output Registration
  // - Registers outputs from Stage 1 combinatorial logic.
  // - These are the module output registers declared in the port list.
  //------------------------------------------------------------------------
  reg valid_s2; // Valid signal registered from S1

  // Stage 2 Registers (Output registers of the module)
  always @(posedge clk_hs) begin
    if (!rst_n) begin
      hs_data_out <= {DATA_LANES{1'b0}};
      hs_clk_out <= 1'b0;
      tx_done <= 1'b0;
      busy <= 1'b0;
      valid_s2 <= 1'b0;
    end else begin
      // Only update outputs if the data is valid for this stage (valid_s1_to_s2 is the input valid)
      if (valid_s1_to_s2) begin
        hs_data_out <= hs_data_out_s1_comb;
        hs_clk_out <= hs_clk_out_s1_comb;
        tx_done <= tx_done_s1_comb;
        busy <= busy_s1_comb;
      end else begin
         // Clear outputs when pipeline is not valid at this stage
         hs_data_out <= {DATA_LANES{1'b0}};
         hs_clk_out <= 1'b0;
         tx_done <= 1'b0;
         busy <= 1'b0;
      end
      valid_s2 <= valid_s1_to_s2; // Register valid signal
    end
  end

endmodule
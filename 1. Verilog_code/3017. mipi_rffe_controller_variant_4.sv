//SystemVerilog
module byte_serializer_parity (
  input wire clk,
  input wire reset_n,
  input wire start, // Pulse to start serialization (one clock cycle)
  input wire [7:0] data_in,
  output reg serial_out,
  output wire parity_out,
  output wire done, // Pulse high for one cycle when serialization is complete
  output wire busy  // High while serialization is in progress
);

  localparam S_IDLE = 2'd0, S_SEND = 2'd1, S_DONE = 2'd2;

  reg [1:0] state;
  reg [3:0] bit_count;
  reg parity_reg;
  reg [7:0] data_reg;

  assign parity_out = parity_reg;
  assign busy = (state == S_SEND);
  assign done = (state == S_DONE);

  // State and Data Register
  // Handles state transitions and loads data when starting.
  always @(posedge clk or negedge reset_n) begin
    if (!reset_n) begin
      state <= S_IDLE;
      data_reg <= 8'd0;
    end else begin
      case (state)
        S_IDLE: begin
          if (start) begin
            state <= S_SEND;
            data_reg <= data_in; // Load data when starting
          end else begin
            state <= S_IDLE;
          end
        end
        S_SEND: begin
          if (bit_count == 4'd0) begin
            state <= S_DONE;
          end else begin
            state <= S_SEND;
          end
        end
        S_DONE: begin
          state <= S_IDLE; // Automatically return to IDLE after one cycle
        end
        default: begin
          state <= S_IDLE;
        end
      endcase
    end
  end

  // Bit Count Register
  // Tracks the current bit being sent.
  always @(posedge clk or negedge reset_n) begin
    if (!reset_n) begin
      bit_count <= 4'd0;
    end else begin
      case (state)
        S_IDLE: begin
          if (start) bit_count <= 4'd7; // Start from MSB (bit 7)
          else       bit_count <= 4'd0;
        end
        S_SEND: begin
          if (bit_count != 4'd0) bit_count <= bit_count - 1'b1;
          // else bit_count stays at 0 before moving to DONE
        end
        S_DONE: begin
          bit_count <= 4'd0; // Reset count
        end
        default: begin
          bit_count <= 4'd0;
        end
      endcase
    end
  end

  // Serial Output Register
  // Drives the serial output signal based on the current bit.
  always @(posedge clk or negedge reset_n) begin
    if (!reset_n) begin
      serial_out <= 1'b1; // RFFE idle/end state is high
    end else begin
      case (state)
        S_IDLE: begin
          serial_out <= 1'b1; // RFFE idle state
        end
        S_SEND: begin
          serial_out <= data_reg[bit_count]; // Output current bit
        end
        S_DONE: begin
          serial_out <= 1'b1; // RFFE end state
        end
        default: begin
          serial_out <= 1'b1;
        end
      endcase
    end
  end

  // Parity Register
  // Calculates and stores the parity.
  always @(posedge clk or negedge reset_n) begin
    if (!reset_n) begin
      parity_reg <= 1'b0;
    end else begin
      case (state)
        S_IDLE: begin
          if (start) parity_reg <= 1'b0; // Reset parity when starting
          else       parity_reg <= parity_reg; // Hold
        end
        S_SEND: begin
          parity_reg <= parity_reg ^ data_reg[bit_count]; // Update parity with current bit
        end
        S_DONE: begin
          // Parity holds its final value for one cycle
        end
        default: begin
          parity_reg <= 1'b0;
        end
      endcase
    end
  end

endmodule


module mipi_rffe_controller (
  input wire clk, reset_n,
  input wire [7:0] command,
  input wire [7:0] address,
  input wire [7:0] write_data,
  input wire start_transaction, is_write,
  output reg sclk, sdata,
  output reg busy, done
);

  // Main FSM states
  localparam IDLE          = 4'd0,
             START         = 4'd1, // SCLK high, SDATA goes low
             SENDING_CMD   = 4'd2,
             SENDING_ADDR  = 4'd3,
             SENDING_DATA  = 4'd4, // Only for write
             SEND_PARITY   = 4'd5,
             END           = 4'd6; // SCLK high, SDATA goes high

  reg [3:0] state;
  reg start_cmd_serializer;
  reg start_addr_serializer;
  reg start_data_serializer;
  reg last_parity; // Stores parity from ADDR or DATA serializer

  // Instantiate serializers
  wire cmd_serial_out;
  wire cmd_parity;
  wire cmd_done;
  wire cmd_busy;

  byte_serializer_parity cmd_serializer (
    .clk(clk),
    .reset_n(reset_n),
    .start(start_cmd_serializer),
    .data_in(command),
    .serial_out(cmd_serial_out),
    .parity_out(cmd_parity), // Not used by controller logic
    .done(cmd_done),
    .busy(cmd_busy)
  );

  wire addr_serial_out;
  wire addr_parity;
  wire addr_done;
  wire addr_busy;

  byte_serializer_parity addr_serializer (
    .clk(clk),
    .reset_n(reset_n),
    .start(start_addr_serializer),
    .data_in(address),
    .serial_out(addr_serial_out),
    .parity_out(addr_parity),
    .done(addr_done),
    .busy(addr_busy)
  );

  wire data_serial_out;
  wire data_parity;
  wire data_done;
  wire data_busy;

  byte_serializer_parity data_serializer (
    .clk(clk),
    .reset_n(reset_n),
    .start(start_data_serializer),
    .data_in(write_data),
    .serial_out(data_serial_out),
    .parity_out(data_parity),
    .done(data_done),
    .busy(data_busy)
  );

  // sdata multiplexing based on state (Combinational)
  // Selects the appropriate serial data or state-dependent value.
  always @(*) begin
    case (state)
      START:       sdata = 1'b0; // Start condition (SDATA low)
      SENDING_CMD: sdata = cmd_serial_out;
      SENDING_ADDR:sdata = addr_serial_out;
      SENDING_DATA:sdata = data_serial_out;
      SEND_PARITY: sdata = last_parity; // Use stored parity
      END:         sdata = 1'b1;   // End condition (SDATA high)
      IDLE:        sdata = 1'b1;  // Idle state (SDATA high)
      default:     sdata = 1'b1;
    endcase
  end

  // State Register (Sequential)
  // Manages the main state machine transitions.
  always @(posedge clk or negedge reset_n) begin
    if (!reset_n) begin
      state <= IDLE;
    end else begin
      case (state)
        IDLE: begin
          if (start_transaction) state <= START; // Start transaction
          else                   state <= IDLE;  // Stay in IDLE
        end
        START: begin
          state <= SENDING_CMD; // Move to sending command
        end
        SENDING_CMD: begin
          if (cmd_done) state <= SENDING_ADDR; // Command sent, move to address
          else          state <= SENDING_CMD; // Wait for command serializer
        end
        SENDING_ADDR: begin
          if (addr_done) begin // Address sent
            if (is_write) state <= SENDING_DATA; // Write transaction: send data
            else          state <= SEND_PARITY; // Read transaction: send parity
          end else begin
            state <= SENDING_ADDR; // Wait for address serializer
          end
        end
        SENDING_DATA: begin
          if (data_done) state <= SEND_PARITY; // Data sent, move to parity
          else          state <= SENDING_DATA; // Wait for data serializer
        end
        SEND_PARITY: begin
          state <= END; // Parity sent, move to end
        end
        END: begin
          state <= IDLE; // Transaction complete, return to IDLE
        end
        default: begin
          state <= IDLE; // Should not happen
        end
      endcase
    end
  end

  // SCLK Register (Sequential)
  // Generates the SCLK signal based on the current state.
  always @(posedge clk or negedge reset_n) begin
    if (!reset_n) begin
      sclk <= 1'b1;
    end else begin
      case (state)
        IDLE, END, START: begin
          sclk <= 1'b1; // SCLK high in IDLE, END, START states
        end
        SENDING_CMD, SENDING_ADDR, SENDING_DATA, SEND_PARITY: begin
          // Toggle SCLK every clock cycle while transmitting data/parity
          sclk <= ~sclk;
        end
        default: begin
          sclk <= 1'b1; // Should not happen
        end
      endcase
    end
  end

  // Control and Status Registers (Sequential)
  // Handles serializer start pulses, busy, done, and parity storage.
  always @(posedge clk or negedge reset_n) begin
    if (!reset_n) begin
      start_cmd_serializer <= 1'b0;
      start_addr_serializer <= 1'b0;
      start_data_serializer <= 1'b0;
      busy <= 1'b0;
      done <= 1'b0;
      last_parity <= 1'b0;
    end else begin
      // Default assignments for pulsed signals (go low unless set high below)
      start_cmd_serializer <= 1'b0;
      start_addr_serializer <= 1'b0;
      start_data_serializer <= 1'b0;
      done <= 1'b0; // done is pulsed high for one cycle

      // Update registers based on current state and inputs/serializer outputs
      case (state)
        IDLE: begin
          last_parity <= 1'b0; // Reset parity when idle
        end
        START: begin
          start_cmd_serializer <= 1'b1; // Pulse high to start command serializer
        end
        SENDING_CMD: begin
          if (cmd_done) begin
            start_addr_serializer <= 1'b1; // Pulse high to start address serializer
          end
        end
        SENDING_ADDR: begin
          if (addr_done) begin
            last_parity <= addr_parity; // Store parity from address
            if (is_write) begin
              start_data_serializer <= 1'b1; // Pulse high to start data serializer if writing
            end
          end
        end
        SENDING_DATA: begin
          if (data_done) begin
            last_parity <= data_parity; // Store parity from data
          end
        end
        SEND_PARITY: begin
          // last_parity is already set
        end
        END: begin
          done <= 1'b1; // Pulse done high for one cycle
        end
        default: begin
          // Defaults handle this
        end
      endcase

      // Handle busy state transitions
      // Busy becomes high when starting from IDLE, and low when entering END.
      if (state == IDLE && start_transaction) begin
         busy <= 1'b1;
      end else if (state == END) begin
         busy <= 1'b0;
      end
      // Otherwise, busy holds its value (remains high during START, SENDING_CMD, ADDR, DATA, PARITY states)
    end
  end

endmodule
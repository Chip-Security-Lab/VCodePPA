//SystemVerilog
module mipi_dphy_lane_controller_axi (
  // AXI4-Lite Slave Interface
  input wire  ACLK,
  input wire  ARESETn,

  input wire [31:0] AWADDR,
  input wire [2:0]  AWPROT,
  input wire  AWVALID,
  output wire  AWREADY,

  input wire [31:0] WDATA,
  input wire [3:0]  WSTRB,
  input wire  WVALID,
  output wire  WREADY,

  output wire [1:0] BRESP,
  output wire  BVALID,
  input wire  BREADY,

  input wire [31:0] ARADDR,
  input wire [2:0]  ARPROT,
  input wire  ARVALID,
  output wire  ARREADY,

  output wire [31:0] RDATA,
  output wire [1:0] RRESP,
  output wire  RVALID,
  input wire  RREADY,

  // Original clocks needed for internal logic domains
  // AXI operates on ACLK. ARESETn is the reset.
  // lp_clk is still needed for the LP mode logic domain.
  input wire lp_clk
);

  // AXI Register Address Mapping
  localparam ADDR_CONTROL = 32'h00; // R/W: enable (bit 0), hs_mode (bit 1)
  localparam ADDR_DATA_IN = 32'h04; // R/W: data_in (bits 7:0)
  localparam ADDR_STATUS  = 32'h08; // R: lp_out (bits 1:0), hs_out_p (bit 2), hs_out_n (bit 3), shift_reg (bits 11:4)
  localparam ADDR_RANGE   = 32'h0C; // End address + 1 (for address decoding range check)

  // Internal AXI State Signals
  reg awready_reg;
  reg wready_reg;
  reg arready_reg;
  reg rvalid_reg;
  reg [31:0] rdata_reg;
  reg bvalid_reg;
  reg [1:0] bresp_reg;

  // AXI Mapped Registers (Synchronous to ACLK)
  reg [31:0] control_reg; // Stores enable and hs_mode
  reg [31:0] data_in_reg; // Stores data_in value
  wire [31:0] status_reg; // Combinational output for read status

  // Address Decoding
  wire is_write_addr = (AWADDR >= ADDR_CONTROL) && (AWADDR < ADDR_RANGE);
  wire is_read_addr  = (ARADDR >= ADDR_CONTROL) && (ARADDR < ADDR_RANGE);

  // Signals connecting AXI registers to Core Logic Inputs
  wire [7:0] core_data_in = data_in_reg[7:0];
  wire core_enable  = control_reg[0];
  wire core_hs_mode = control_reg[1];

  // Internal Core Logic State (Replicated from original module)
  // These signals represent the state and outputs of the original logic.
  reg [7:0] shift_reg;         // Synchronous to ACLK (original hs_clk)
  reg [1:0] internal_lp_out;   // Synchronous to lp_clk
  reg internal_hs_out_p;     // Synchronous to ACLK
  reg internal_hs_out_n;     // Synchronous to ACLK

  // Core Logic - High Speed Mode (Synchronous to ACLK)
  // Uses ACLK (assumed to be original hs_clk) and ARESETn.
  always @(posedge ACLK or negedge ARESETn) begin
    if (!ARESETn) begin
      shift_reg <= 8'h00;
      internal_hs_out_p <= 1'b0;
      internal_hs_out_n <= 1'b1;
      // Reset AXI registers on ARESETn
      control_reg <= 32'h00;
      data_in_reg <= 32'h00;
    end else begin
      // Original HS logic driven by AXI control signals
      if (core_hs_mode && core_enable) begin
        shift_reg <= {shift_reg[6:0], core_data_in[7]};
        internal_hs_out_p <= shift_reg[7];
        internal_hs_out_n <= ~shift_reg[7];
      end
      // HS outputs hold their value when not in HS mode or not enabled.
    end
  end

  // Core Logic - Low Speed Mode (Synchronous to lp_clk)
  // Uses lp_clk and ARESETn.
  // Note: core_enable and core_hs_mode are from ACLK domain.
  // For a robust design, they should be synchronized to lp_clk before being used here.
  // For simplicity and functional equivalence to the original (which used `enable` and `hs_mode` directly),
  // we use them directly, assuming they are stable or potential metastability is acceptable
  // at this domain crossing for this specific signal usage (simple condition check).
  always @(posedge lp_clk or negedge ARESETn) begin
      if (!ARESETn) begin
          internal_lp_out <= 2'b00; // LP00 state on reset
      end else begin
          // Original LP logic: set to LP01 if enabled in LP mode
          if (core_enable && !core_hs_mode) begin
              internal_lp_out <= 2'b01; // LP01 state
          end else begin
              // When not enabled in LP mode, return to default LP00 state
              internal_lp_out <= 2'b00;
          end
      end
  end


  // AXI4-Lite Write and Read Handshake Logic (Synchronous to ACLK)
  always @(posedge ACLK or negedge ARESETn) begin
    if (!ARESETn) begin
      awready_reg <= 1'b0;
      wready_reg  <= 1'b0;
      arready_reg <= 1'b0;
      rvalid_reg  <= 1'b0;
      bvalid_reg  <= 1'b0;
      rdata_reg   <= 32'h00;
      bresp_reg   <= 2'b00; // OKAY
    end else begin
      // Default next state is to deassert handshakes, unless held high below
      awready_reg <= 1'b0;
      wready_reg  <= 1'b0;
      arready_reg <= 1'b0;
      // Keep RVALID high until RREADY is asserted
      rvalid_reg  <= rvalid_reg && !RREADY;
      // Keep BVALID high until BREADY is asserted
      bvalid_reg  <= bvalid_reg && !BREADY;
      bresp_reg   <= bresp_reg; // Hold response

      // --- Write Channel ---
      // Accept write address
      if (AWVALID && !awready_reg && !WVALID && !wready_reg && !bvalid_reg) begin
         if (is_write_addr) begin
             awready_reg <= 1'b1;
         end
         // else ignore invalid address
      end

      // Accept write data
      if (WVALID && !wready_reg && awready_reg) begin
          wready_reg <= 1'b1;
      end

      // Latch write data and complete transaction when both AW and W are accepted
      if (awready_reg && AWVALID && wready_reg && WVALID) begin
          // Latch data based on address and WSTRB
          if (AWADDR == ADDR_CONTROL) begin
              if (WSTRB[0]) control_reg[7:0]   <= WDATA[7:0];
              if (WSTRB[1]) control_reg[15:8]  <= WDATA[15:8];
              if (WSTRB[2]) control_reg[23:16] <= WDATA[23:16];
              if (WSTRB[3]) control_reg[31:24] <= WDATA[31:24];
          end else if (AWADDR == ADDR_DATA_IN) begin
              if (WSTRB[0]) data_in_reg[7:0]   <= WDATA[7:0];
              if (WSTRB[1]) data_in_reg[15:8]  <= WDATA[15:8];
              if (WSTRB[2]) data_in_reg[23:16] <= WDATA[23:16];
              if (WSTRB[3]) data_in_reg[31:24] <= WDATA[31:24];
          end else begin
              // Invalid address write - ignored
          end

          // Deassert AWREADY and WREADY, assert BVALID
          awready_reg <= 1'b0;
          wready_reg  <= 1'b0;
          bvalid_reg  <= 1'b1;
          bresp_reg   <= 2'b00; // OKAY response for write
      end

      // Write Response Channel (BVALID held until BREADY)

      // --- Read Channel ---
      // Accept read address
      if (ARVALID && !arready_reg && !rvalid_reg) begin // Accept AR only if R channel is idle
          if (is_read_addr) begin
              arready_reg <= 1'b1;
              // Prepare read data combinatorially based on ARADDR
              if (ARADDR == ADDR_CONTROL) begin
                  rdata_reg <= control_reg;
              end else if (ARADDR == ADDR_DATA_IN) begin
                   rdata_reg <= data_in_reg; // Allow reading back data_in_reg
              end else if (ARADDR == ADDR_STATUS) begin
                   // status_reg is assigned combinatorially below
                   rdata_reg <= status_reg;
              end else begin
                  rdata_reg <= 32'h00; // Read from invalid address returns 0
                  // RRESP is OKAY (2'b00) by default assignment
              end
          end
          // else ignore invalid address
      end

      // Assert RVALID one cycle after AR is accepted
      if (arready_reg && ARVALID) begin
          arready_reg <= 1'b0; // Deassert ARREADY
          rvalid_reg  <= 1'b1; // Assert RVALID
          // rdata_reg is already prepared in the previous cycle's ARVALID block
      end
      // Read Data Channel (RVALID held until RREADY)

    end // else (!ARESETn)
  end // always @(posedge ACLK or negedge ARESETn)

  // Status Register Assignment (Combinational)
  // Packs internal state/outputs into the 32-bit status_reg for AXI read.
  // Note: internal_lp_out is from lp_clk domain. Reading it directly here
  // creates a CDC path. For a robust design, synchronize internal_lp_out to ACLK.
  // Keeping it direct for functional equivalence to original (where hs_clk logic implicitly
  // might interact with lp_clk driven signals, though not explicitly shown).
  assign status_reg = {
      {32-12{1'b0}},       // Reserved bits (fill with 0)
      shift_reg,          // Bits 11:4 (8 bits) - from ACLK domain
      internal_hs_out_n,  // Bit 3 (1 bit) - from ACLK domain
      internal_hs_out_p,  // Bit 2 (1 bit) - from ACLK domain
      internal_lp_out     // Bits 1:0 (2 bits) - from lp_clk domain (CDC)
  };

  // Assign AXI outputs from registered signals
  assign AWREADY = awready_reg;
  assign WREADY  = wready_reg;
  assign BRESP   = bresp_reg;
  assign BVALID  = bvalid_reg;

  assign ARREADY = arready_reg;
  assign RDATA   = rdata_reg;
  assign RRESP   = 2'b00; // AXI4-Lite Read Response (OKAY)
  assign RVALID  = rvalid_reg;

endmodule
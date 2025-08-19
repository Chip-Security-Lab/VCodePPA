//SystemVerilog - IEEE 1364-2005
module can_frame_assembler (
  // Global signals
  input  wire        s_axi_aclk,
  input  wire        s_axi_aresetn,
  
  // AXI4-Lite Write Address Channel
  input  wire [7:0]  s_axi_awaddr,
  input  wire        s_axi_awvalid,
  output reg         s_axi_awready,
  
  // AXI4-Lite Write Data Channel
  input  wire [31:0] s_axi_wdata,
  input  wire [3:0]  s_axi_wstrb,
  input  wire        s_axi_wvalid,
  output reg         s_axi_wready,
  
  // AXI4-Lite Write Response Channel
  output reg [1:0]   s_axi_bresp,
  output reg         s_axi_bvalid,
  input  wire        s_axi_bready,
  
  // AXI4-Lite Read Address Channel
  input  wire [7:0]  s_axi_araddr,
  input  wire        s_axi_arvalid,
  output reg         s_axi_arready,
  
  // AXI4-Lite Read Data Channel
  output reg [31:0]  s_axi_rdata,
  output reg [1:0]   s_axi_rresp,
  output reg         s_axi_rvalid,
  input  wire        s_axi_rready
);

  // Register map
  localparam REG_ID         = 8'h00; // ID[10:0], RTR, IDE
  localparam REG_DATA_0     = 8'h04; // data[0], data[1], data[2], data[3]
  localparam REG_DATA_1     = 8'h08; // data[4], data[5], data[6], data[7]
  localparam REG_DLC        = 8'h0C; // DLC[3:0]
  localparam REG_CONTROL    = 8'h10; // [0] = assemble
  localparam REG_STATUS     = 8'h14; // [0] = frame_ready
  localparam REG_FRAME_0    = 8'h18; // frame[31:0]
  localparam REG_FRAME_1    = 8'h1C; // frame[63:32]
  localparam REG_FRAME_2    = 8'h20; // frame[95:64]
  localparam REG_FRAME_3    = 8'h24; // frame[127:96]
  
  // Internal registers
  reg [10:0] id_reg;
  reg [7:0]  data_reg [0:7];
  reg [3:0]  dlc_reg;
  reg        rtr_reg, ide_reg, assemble_reg;
  reg [127:0] frame_reg;
  reg        frame_ready_reg;
  
  // FSM states
  localparam IDLE           = 8'h00;
  localparam ASSEMBLE_FRAME = 8'h01;
  reg [7:0]  state, next_state;
  
  // Internal signals for frame assembly
  reg [127:0] frame_next;
  reg        frame_ready_next;
  
  // AXI channel signals
  wire        aw_handshake_done;
  wire        w_handshake_done;
  wire        b_handshake_done;
  wire        ar_handshake_done;
  wire        r_handshake_done;
  
  // Address capture registers
  reg [7:0]  write_addr;
  reg        write_addr_valid;
  reg [7:0]  read_addr;
  reg        read_addr_valid;
  
  // Handshake completion signals
  assign aw_handshake_done = s_axi_awready && s_axi_awvalid;
  assign w_handshake_done = s_axi_wready && s_axi_wvalid;
  assign b_handshake_done = s_axi_bvalid && s_axi_bready;
  assign ar_handshake_done = s_axi_arready && s_axi_arvalid;
  assign r_handshake_done = s_axi_rvalid && s_axi_rready;
  
  // Instantiate AXI address channel modules
  axi_addr_channel #(
    .CHANNEL_TYPE("WRITE")
  ) axi_write_addr_channel (
    .clk(s_axi_aclk),
    .resetn(s_axi_aresetn),
    .addr_valid(s_axi_awvalid),
    .addr(s_axi_awaddr),
    .addr_ready(s_axi_awready),
    .data_handshake_done(w_handshake_done),
    .captured_addr(write_addr),
    .addr_valid_out(write_addr_valid)
  );

  axi_addr_channel #(
    .CHANNEL_TYPE("READ")
  ) axi_read_addr_channel (
    .clk(s_axi_aclk),
    .resetn(s_axi_aresetn),
    .addr_valid(s_axi_arvalid),
    .addr(s_axi_araddr),
    .addr_ready(s_axi_arready),
    .data_handshake_done(r_handshake_done),
    .captured_addr(read_addr),
    .addr_valid_out(read_addr_valid)
  );
  
  // AXI write data channel logic
  always @(posedge s_axi_aclk or negedge s_axi_aresetn) begin
    if (!s_axi_aresetn) begin
      s_axi_wready <= 1'b0;
      id_reg <= 11'h0;
      rtr_reg <= 1'b0;
      ide_reg <= 1'b0;
      dlc_reg <= 4'h0;
      assemble_reg <= 1'b0;
      
      // Initialize data registers
      for (int i = 0; i < 8; i = i + 1)
        data_reg[i] <= 8'h0;
    end else begin
      // Clear assemble flag after frame is assembled
      if (state == ASSEMBLE_FRAME) begin
        assemble_reg <= 1'b0;
      end
      
      if (~s_axi_wready && s_axi_wvalid && write_addr_valid) begin
        s_axi_wready <= 1'b1;
        
        case (write_addr)
          REG_ID: begin
            if (s_axi_wstrb[0]) begin
              id_reg[7:0] <= s_axi_wdata[7:0];
            end
            if (s_axi_wstrb[1]) begin
              id_reg[10:8] <= s_axi_wdata[10:8];
              rtr_reg <= s_axi_wdata[11];
              ide_reg <= s_axi_wdata[12];
            end
          end
          
          REG_DATA_0: begin
            if (s_axi_wstrb[0]) data_reg[0] <= s_axi_wdata[7:0];
            if (s_axi_wstrb[1]) data_reg[1] <= s_axi_wdata[15:8];
            if (s_axi_wstrb[2]) data_reg[2] <= s_axi_wdata[23:16];
            if (s_axi_wstrb[3]) data_reg[3] <= s_axi_wdata[31:24];
          end
          
          REG_DATA_1: begin
            if (s_axi_wstrb[0]) data_reg[4] <= s_axi_wdata[7:0];
            if (s_axi_wstrb[1]) data_reg[5] <= s_axi_wdata[15:8];
            if (s_axi_wstrb[2]) data_reg[6] <= s_axi_wdata[23:16];
            if (s_axi_wstrb[3]) data_reg[7] <= s_axi_wdata[31:24];
          end
          
          REG_DLC: begin
            if (s_axi_wstrb[0]) dlc_reg <= s_axi_wdata[3:0];
          end
          
          REG_CONTROL: begin
            if (s_axi_wstrb[0]) assemble_reg <= s_axi_wdata[0];
          end
        endcase
      end else begin
        s_axi_wready <= 1'b0;
      end
    end
  end
  
  // Instantiate AXI response channel module
  axi_response_channel axi_write_resp_channel (
    .clk(s_axi_aclk),
    .resetn(s_axi_aresetn),
    .handshake_done(w_handshake_done),
    .resp_ready(s_axi_bready),
    .resp_valid(s_axi_bvalid),
    .resp(s_axi_bresp)
  );
  
  // AXI read data channel logic
  always @(posedge s_axi_aclk or negedge s_axi_aresetn) begin
    if (!s_axi_aresetn) begin
      s_axi_rvalid <= 1'b0;
      s_axi_rresp <= 2'b0;
      s_axi_rdata <= 32'h0;
    end else begin
      if (read_addr_valid && ~s_axi_rvalid) begin
        s_axi_rvalid <= 1'b1;
        s_axi_rresp <= 2'b00; // OKAY response
        
        case (read_addr)
          REG_ID:      s_axi_rdata <= {19'h0, ide_reg, rtr_reg, id_reg};
          REG_DATA_0:  s_axi_rdata <= {data_reg[3], data_reg[2], data_reg[1], data_reg[0]};
          REG_DATA_1:  s_axi_rdata <= {data_reg[7], data_reg[6], data_reg[5], data_reg[4]};
          REG_DLC:     s_axi_rdata <= {28'h0, dlc_reg};
          REG_CONTROL: s_axi_rdata <= {31'h0, assemble_reg};
          REG_STATUS:  s_axi_rdata <= {31'h0, frame_ready_reg};
          REG_FRAME_0: s_axi_rdata <= frame_reg[31:0];
          REG_FRAME_1: s_axi_rdata <= frame_reg[63:32];
          REG_FRAME_2: s_axi_rdata <= frame_reg[95:64];
          REG_FRAME_3: s_axi_rdata <= frame_reg[127:96];
          default:     s_axi_rdata <= 32'h0;
        endcase
      end else if (s_axi_rvalid && s_axi_rready) begin
        s_axi_rvalid <= 1'b0;
      end
    end
  end
  
  // Instantiate frame assembly module
  can_frame_constructor frame_assembler (
    .clk(s_axi_aclk),
    .resetn(s_axi_aresetn),
    .state(state),
    .next_state(next_state),
    .assemble_req(assemble_reg),
    .id(id_reg),
    .rtr(rtr_reg),
    .ide(ide_reg),
    .dlc(dlc_reg),
    .data(data_reg),
    .frame_reg(frame_reg),
    .frame_ready_reg(frame_ready_reg),
    .frame_next(frame_next),
    .frame_ready_next(frame_ready_next)
  );
  
  // State and output register update
  always @(posedge s_axi_aclk or negedge s_axi_aresetn) begin
    if (!s_axi_aresetn) begin
      state <= IDLE;
      frame_reg <= 128'b0;
      frame_ready_reg <= 1'b0;
    end else begin
      state <= next_state;
      frame_reg <= frame_next;
      frame_ready_reg <= frame_ready_next;
    end
  end

endmodule

// AXI Address Channel Handler Module
module axi_addr_channel #(
  parameter CHANNEL_TYPE = "WRITE" // "WRITE" or "READ"
)(
  input  wire        clk,
  input  wire        resetn,
  input  wire        addr_valid,
  input  wire [7:0]  addr,
  output reg         addr_ready,
  input  wire        data_handshake_done,
  output reg  [7:0]  captured_addr,
  output reg         addr_valid_out
);

  always @(posedge clk or negedge resetn) begin
    if (!resetn) begin
      addr_ready <= 1'b0;
      captured_addr <= 8'h0;
      addr_valid_out <= 1'b0;
    end else begin
      if (~addr_ready && addr_valid) begin
        addr_ready <= 1'b1;
        captured_addr <= addr;
        addr_valid_out <= 1'b1;
      end else begin
        addr_ready <= 1'b0;
        if (data_handshake_done) begin
          addr_valid_out <= 1'b0;
        end
      end
    end
  end

endmodule

// AXI Response Channel Handler Module
module axi_response_channel (
  input  wire        clk,
  input  wire        resetn,
  input  wire        handshake_done,
  input  wire        resp_ready,
  output reg         resp_valid,
  output reg  [1:0]  resp
);

  always @(posedge clk or negedge resetn) begin
    if (!resetn) begin
      resp_valid <= 1'b0;
      resp <= 2'b0;
    end else begin
      if (handshake_done && ~resp_valid) begin
        resp_valid <= 1'b1;
        resp <= 2'b00; // OKAY response
      end else if (resp_valid && resp_ready) begin
        resp_valid <= 1'b0;
      end
    end
  end

endmodule

// CAN Frame Constructor Module
module can_frame_constructor (
  input  wire        clk,
  input  wire        resetn,
  input  wire [7:0]  state,
  output wire [7:0]  next_state,
  input  wire        assemble_req,
  input  wire [10:0] id,
  input  wire        rtr,
  input  wire        ide,
  input  wire [3:0]  dlc,
  input  wire [7:0]  data [0:7],
  input  wire [127:0] frame_reg,
  input  wire        frame_ready_reg,
  output reg  [127:0] frame_next,
  output reg         frame_ready_next
);

  // FSM states (imported from top module)
  localparam IDLE           = 8'h00;
  localparam ASSEMBLE_FRAME = 8'h01;
  
  reg [7:0] next_state_reg;
  assign next_state = next_state_reg;
  
  // Frame assembly state machine
  always @(*) begin
    next_state_reg = state;
    frame_next = frame_reg;
    frame_ready_next = frame_ready_reg;
    
    case (state)
      IDLE: begin
        if (assemble_req) begin
          next_state_reg = ASSEMBLE_FRAME;
          
          // Parallel assembly of all fields
          frame_next = 128'b0;
          frame_next[0] = 1'b0; // SOF
          frame_next[11:1] = id;
          frame_next[12] = rtr;
          frame_next[13] = ide;
          frame_next[14] = 1'b0; // r0 reserved bit
          frame_next[18:15] = dlc;
          
          // Optimize data field processing - only fill for non-RTR frames
          if (!rtr) begin
            frame_next[26:19] = data[0];
            frame_next[34:27] = data[1];
            frame_next[42:35] = data[2];
            frame_next[50:43] = data[3];
            frame_next[58:51] = data[4];
            frame_next[66:59] = data[5];
            frame_next[74:67] = data[6];
            frame_next[82:75] = data[7];
          end
          
          frame_ready_next = 1'b1;
        end
      end
      
      ASSEMBLE_FRAME: begin
        // Return to IDLE state after completing a frame
        next_state_reg = IDLE;
        frame_ready_next = 1'b0;
      end
      
      default: next_state_reg = IDLE;
    endcase
  end

endmodule
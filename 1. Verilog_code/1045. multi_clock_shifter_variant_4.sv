//SystemVerilog
module multi_clock_shifter_axi4lite #(
  parameter ADDR_WIDTH = 4
)(
  // AXI4-Lite Clock and Reset
  input  wire                  S_AXI_ACLK,
  input  wire                  S_AXI_ARESETN,
  // AXI4-Lite Write Address Channel
  input  wire [ADDR_WIDTH-1:0] S_AXI_AWADDR,
  input  wire                  S_AXI_AWVALID,
  output reg                   S_AXI_AWREADY,
  // AXI4-Lite Write Data Channel
  input  wire [7:0]            S_AXI_WDATA,
  input  wire [0:0]            S_AXI_WSTRB,
  input  wire                  S_AXI_WVALID,
  output reg                   S_AXI_WREADY,
  // AXI4-Lite Write Response Channel
  output reg  [1:0]            S_AXI_BRESP,
  output reg                   S_AXI_BVALID,
  input  wire                  S_AXI_BREADY,
  // AXI4-Lite Read Address Channel
  input  wire [ADDR_WIDTH-1:0] S_AXI_ARADDR,
  input  wire                  S_AXI_ARVALID,
  output reg                   S_AXI_ARREADY,
  // AXI4-Lite Read Data Channel
  output reg  [7:0]            S_AXI_RDATA,
  output reg  [1:0]            S_AXI_RRESP,
  output reg                   S_AXI_RVALID,
  input  wire                  S_AXI_RREADY
);

  // Internal registers
  reg [7:0]  reg_data_in;
  reg [2:0]  reg_shift_a;
  reg [2:0]  reg_shift_b;
  reg [7:0]  reg_data_out;
  reg [7:0]  stage_a;

  // Write FSM states
  localparam [1:0] WR_IDLE = 2'd0,
                   WR_DATA = 2'd1,
                   WR_RESP = 2'd2;
  reg [1:0] wr_state;

  // Read FSM states
  localparam [1:0] RD_IDLE = 2'd0,
                   RD_DATA = 2'd1;
  reg [1:0] rd_state;

  // Address decode
  localparam ADDR_DATA_IN  = 4'h0;
  localparam ADDR_SHIFT_A  = 4'h4;
  localparam ADDR_SHIFT_B  = 4'h8;
  localparam ADDR_DATA_OUT = 4'hC;

  // AXI4-Lite Write Address handshake
  always @(posedge S_AXI_ACLK) begin
    if (!S_AXI_ARESETN) begin
      S_AXI_AWREADY <= 1'b0;
      S_AXI_WREADY  <= 1'b0;
      S_AXI_BVALID  <= 1'b0;
      S_AXI_BRESP   <= 2'b00;
      wr_state      <= WR_IDLE;
    end else begin
      case (wr_state)
        WR_IDLE: begin
          S_AXI_AWREADY <= 1'b1;
          S_AXI_WREADY  <= 1'b1;
          if (S_AXI_AWVALID && S_AXI_WVALID) begin
            wr_state      <= WR_RESP;
            S_AXI_AWREADY <= 1'b0;
            S_AXI_WREADY  <= 1'b0;
            S_AXI_BVALID  <= 1'b1;
            S_AXI_BRESP   <= 2'b00; // OKAY response
            // Write register selected by address
            case (S_AXI_AWADDR[ADDR_WIDTH-1:0])
              ADDR_DATA_IN: if (S_AXI_WSTRB[0]) reg_data_in <= S_AXI_WDATA;
              ADDR_SHIFT_A: if (S_AXI_WSTRB[0]) reg_shift_a <= S_AXI_WDATA[2:0];
              ADDR_SHIFT_B: if (S_AXI_WSTRB[0]) reg_shift_b <= S_AXI_WDATA[2:0];
              default: ;
            endcase
          end
        end
        WR_RESP: begin
          if (S_AXI_BREADY) begin
            S_AXI_BVALID  <= 1'b0;
            wr_state      <= WR_IDLE;
          end
        end
        default: wr_state <= WR_IDLE;
      endcase
    end
  end

  // AXI4-Lite Read Address handshake
  always @(posedge S_AXI_ACLK) begin
    if (!S_AXI_ARESETN) begin
      S_AXI_ARREADY <= 1'b0;
      S_AXI_RVALID  <= 1'b0;
      S_AXI_RDATA   <= 8'd0;
      S_AXI_RRESP   <= 2'b00;
      rd_state      <= RD_IDLE;
    end else begin
      case (rd_state)
        RD_IDLE: begin
          S_AXI_ARREADY <= 1'b1;
          if (S_AXI_ARVALID) begin
            S_AXI_ARREADY <= 1'b0;
            S_AXI_RVALID  <= 1'b1;
            S_AXI_RRESP   <= 2'b00; // OKAY
            case (S_AXI_ARADDR[ADDR_WIDTH-1:0])
              ADDR_DATA_IN:  S_AXI_RDATA <= reg_data_in;
              ADDR_SHIFT_A:  S_AXI_RDATA <= {5'd0, reg_shift_a};
              ADDR_SHIFT_B:  S_AXI_RDATA <= {5'd0, reg_shift_b};
              ADDR_DATA_OUT: S_AXI_RDATA <= reg_data_out;
              default:       S_AXI_RDATA <= 8'd0;
            endcase
            rd_state <= RD_DATA;
          end
        end
        RD_DATA: begin
          if (S_AXI_RREADY) begin
            S_AXI_RVALID <= 1'b0;
            rd_state     <= RD_IDLE;
          end
        end
        default: rd_state <= RD_IDLE;
      endcase
    end
  end

  // Shifter logic in "A" clock domain (AXI clock)
  always @(posedge S_AXI_ACLK) begin
    if (!S_AXI_ARESETN) begin
      stage_a <= 8'd0;
    end else begin
      case (reg_shift_a)
        3'd0: stage_a <= reg_data_in;
        3'd1: stage_a <= {reg_data_in[6:0], 1'b0};
        3'd2: stage_a <= {reg_data_in[5:0], 2'b0};
        3'd3: stage_a <= {reg_data_in[4:0], 3'b0};
        3'd4: stage_a <= {reg_data_in[3:0], 4'b0};
        3'd5: stage_a <= {reg_data_in[2:0], 5'b0};
        3'd6: stage_a <= {reg_data_in[1:0], 6'b0};
        3'd7: stage_a <= {reg_data_in[0],   7'b0};
        default: stage_a <= 8'b0;
      endcase
    end
  end

  // Shifter logic in "B" clock domain (AXI clock)
  always @(posedge S_AXI_ACLK) begin
    if (!S_AXI_ARESETN) begin
      reg_data_out <= 8'd0;
    end else begin
      case (reg_shift_b)
        3'd0: reg_data_out <= stage_a;
        3'd1: reg_data_out <= {1'b0, stage_a[7:1]};
        3'd2: reg_data_out <= {2'b0, stage_a[7:2]};
        3'd3: reg_data_out <= {3'b0, stage_a[7:3]};
        3'd4: reg_data_out <= {4'b0, stage_a[7:4]};
        3'd5: reg_data_out <= {5'b0, stage_a[7:5]};
        3'd6: reg_data_out <= {6'b0, stage_a[7:6]};
        3'd7: reg_data_out <= {7'b0, stage_a[7]};
        default: reg_data_out <= 8'b0;
      endcase
    end
  end

endmodule
//SystemVerilog
module mipi_csi_image_extractor_axi_lite (
  // AXI4-Lite Interface
  input wire aclk,
  input wire aresetn,
  
  // Write Address Channel
  input wire [31:0] awaddr,
  input wire awvalid,
  output reg awready,
  
  // Write Data Channel
  input wire [31:0] wdata,
  input wire [3:0] wstrb,
  input wire wvalid,
  output reg wready,
  
  // Write Response Channel
  output reg [1:0] bresp,
  output reg bvalid,
  input wire bready,
  
  // Read Address Channel
  input wire [31:0] araddr,
  input wire arvalid,
  output reg arready,
  
  // Read Data Channel
  output reg [31:0] rdata,
  output reg [1:0] rresp,
  output reg rvalid,
  input wire rready,
  
  // MIPI CSI Interface
  input wire [31:0] packet_data,
  input wire packet_valid,
  input wire packet_start,
  input wire packet_end,
  input wire [7:0] packet_type,
  output reg [15:0] pixel_data,
  output reg pixel_valid,
  output reg frame_start,
  output reg frame_end,
  output reg line_start,
  output reg line_end
);

  localparam FRAME_START = 8'h00, LINE_START = 8'h01;
  localparam FRAME_END = 8'h02, LINE_END = 8'h03, RAW_10 = 8'h2B;
  
  // Pipeline stages
  reg [2:0] state_stage1, state_stage2, state_stage3;
  reg [31:0] data_buffer_stage1, data_buffer_stage2;
  reg [1:0] pixel_count_stage1, pixel_count_stage2;
  reg packet_valid_stage1, packet_valid_stage2;
  reg packet_start_stage1, packet_start_stage2;
  reg packet_end_stage1, packet_end_stage2;
  reg [7:0] packet_type_stage1, packet_type_stage2;
  reg [31:0] packet_data_stage1, packet_data_stage2;
  
  // AXI4-Lite Write State Machine
  reg [1:0] write_state_stage1, write_state_stage2;
  localparam WRITE_IDLE = 2'd0, WRITE_ADDR = 2'd1, WRITE_DATA = 2'd2, WRITE_RESP = 2'd3;
  
  // AXI4-Lite Read State Machine
  reg [1:0] read_state_stage1, read_state_stage2;
  localparam READ_IDLE = 2'd0, READ_ADDR = 2'd1, READ_DATA = 2'd2;
  
  // Control Registers
  reg [31:0] control_reg;
  reg [31:0] status_reg;
  
  // Write State Machine Pipeline
  always @(posedge aclk or negedge aresetn) begin
    if (!aresetn) begin
      write_state_stage1 <= WRITE_IDLE;
      write_state_stage2 <= WRITE_IDLE;
      awready <= 1'b0;
      wready <= 1'b0;
      bvalid <= 1'b0;
      bresp <= 2'b00;
      control_reg <= 32'd0;
    end else begin
      write_state_stage2 <= write_state_stage1;
      
      case (write_state_stage1)
        WRITE_IDLE: begin
          awready <= 1'b1;
          wready <= 1'b0;
          bvalid <= 1'b0;
          if (awvalid) begin
            write_state_stage1 <= WRITE_ADDR;
            awready <= 1'b0;
          end
        end
        WRITE_ADDR: begin
          wready <= 1'b1;
          if (wvalid) begin
            write_state_stage1 <= WRITE_DATA;
            wready <= 1'b0;
            case (awaddr[7:0])
              8'h00: control_reg <= wdata;
            endcase
          end
        end
        WRITE_DATA: begin
          write_state_stage1 <= WRITE_RESP;
          bvalid <= 1'b1;
          bresp <= 2'b00;
        end
        WRITE_RESP: begin
          if (bready) begin
            write_state_stage1 <= WRITE_IDLE;
            bvalid <= 1'b0;
          end
        end
      endcase
    end
  end
  
  // Read State Machine Pipeline
  always @(posedge aclk or negedge aresetn) begin
    if (!aresetn) begin
      read_state_stage1 <= READ_IDLE;
      read_state_stage2 <= READ_IDLE;
      arready <= 1'b0;
      rvalid <= 1'b0;
      rresp <= 2'b00;
    end else begin
      read_state_stage2 <= read_state_stage1;
      
      case (read_state_stage1)
        READ_IDLE: begin
          arready <= 1'b1;
          rvalid <= 1'b0;
          if (arvalid) begin
            read_state_stage1 <= READ_ADDR;
            arready <= 1'b0;
          end
        end
        READ_ADDR: begin
          read_state_stage1 <= READ_DATA;
          rvalid <= 1'b1;
          case (araddr[7:0])
            8'h00: rdata <= control_reg;
            8'h04: rdata <= status_reg;
            default: rdata <= 32'd0;
          endcase
          rresp <= 2'b00;
        end
        READ_DATA: begin
          if (rready) begin
            read_state_stage1 <= READ_IDLE;
            rvalid <= 1'b0;
          end
        end
      endcase
    end
  end
  
  // MIPI CSI Processing Pipeline
  always @(posedge aclk or negedge aresetn) begin
    if (!aresetn) begin
      state_stage1 <= 3'd0;
      state_stage2 <= 3'd0;
      state_stage3 <= 3'd0;
      pixel_valid <= 1'b0;
      frame_start <= 1'b0;
      frame_end <= 1'b0;
      line_start <= 1'b0;
      line_end <= 1'b0;
      status_reg <= 32'd0;
      
      packet_valid_stage1 <= 1'b0;
      packet_valid_stage2 <= 1'b0;
      packet_start_stage1 <= 1'b0;
      packet_start_stage2 <= 1'b0;
      packet_end_stage1 <= 1'b0;
      packet_end_stage2 <= 1'b0;
      packet_type_stage1 <= 8'd0;
      packet_type_stage2 <= 8'd0;
      packet_data_stage1 <= 32'd0;
      packet_data_stage2 <= 32'd0;
      data_buffer_stage1 <= 32'd0;
      data_buffer_stage2 <= 32'd0;
      pixel_count_stage1 <= 2'd0;
      pixel_count_stage2 <= 2'd0;
    end else begin
      // Stage 1: Input sampling
      packet_valid_stage1 <= packet_valid;
      packet_start_stage1 <= packet_start;
      packet_end_stage1 <= packet_end;
      packet_type_stage1 <= packet_type;
      packet_data_stage1 <= packet_data;
      
      // Stage 2: Packet processing
      packet_valid_stage2 <= packet_valid_stage1;
      packet_start_stage2 <= packet_start_stage1;
      packet_end_stage2 <= packet_end_stage1;
      packet_type_stage2 <= packet_type_stage1;
      packet_data_stage2 <= packet_data_stage1;
      
      state_stage2 <= state_stage1;
      data_buffer_stage2 <= data_buffer_stage1;
      pixel_count_stage2 <= pixel_count_stage1;
      
      // Stage 3: Output generation
      state_stage3 <= state_stage2;
      
      pixel_valid <= 1'b0;
      frame_start <= 1'b0;
      frame_end <= 1'b0;
      line_start <= 1'b0;
      line_end <= 1'b0;
      
      if (packet_valid_stage2) begin
        if (packet_start_stage2 && packet_type_stage2 == FRAME_START) begin
          frame_start <= 1'b1;
          status_reg[0] <= 1'b1;
        end
        else if (packet_start_stage2 && packet_type_stage2 == LINE_START) begin
          line_start <= 1'b1;
          status_reg[1] <= 1'b1;
        end
        else if (packet_end_stage2 && packet_type_stage2 == FRAME_END) begin
          frame_end <= 1'b1;
          status_reg[2] <= 1'b1;
        end
        else if (packet_end_stage2 && packet_type_stage2 == LINE_END) begin
          line_end <= 1'b1;
          status_reg[3] <= 1'b1;
        end
        else if (packet_type_stage2 == RAW_10) begin
          data_buffer_stage1 <= packet_data_stage2;
          pixel_count_stage1 <= 2'd0;
          state_stage1 <= 3'd1;
        end
      end
      
      if (state_stage3 == 3'd1) begin
        case (pixel_count_stage2)
          2'd0: pixel_data <= {data_buffer_stage2[9:0], 6'b0};
          2'd1: pixel_data <= {data_buffer_stage2[19:10], 6'b0};
          2'd2: pixel_data <= {data_buffer_stage2[29:20], 6'b0};
          2'd3: pixel_data <= {data_buffer_stage2[31:30], 8'b0, 6'b0};
        endcase
        pixel_valid <= 1'b1;
        pixel_count_stage1 <= pixel_count_stage2 + 1'b1;
        if (pixel_count_stage2 == 2'd3) state_stage1 <= 3'd0;
      end
    end
  end
endmodule
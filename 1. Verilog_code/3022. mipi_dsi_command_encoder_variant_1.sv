//SystemVerilog
module mipi_dsi_command_encoder (
  // AXI4-Lite Interface
  input wire ACLK,
  input wire ARESETn,
  
  // Write Address Channel
  input wire [31:0] AWADDR,
  input wire AWVALID,
  output reg AWREADY,
  
  // Write Data Channel
  input wire [31:0] WDATA,
  input wire [3:0] WSTRB,
  input wire WVALID,
  output reg WREADY,
  
  // Write Response Channel
  output reg [1:0] BRESP,
  output reg BVALID,
  input wire BREADY,
  
  // Read Address Channel
  input wire [31:0] ARADDR,
  input wire ARVALID,
  output reg ARREADY,
  
  // Read Data Channel
  output reg [31:0] RDATA,
  output reg [1:0] RRESP,
  output reg RVALID,
  input wire RREADY,
  
  // Internal signals
  output reg [31:0] packet_data,
  output reg packet_ready,
  output reg busy
);

  // Pipeline stages
  reg [3:0] state_stage1, state_stage2, state_stage3;
  reg [3:0] param_idx_stage1, param_idx_stage2;
  reg [7:0] cmd_type_stage1, cmd_type_stage2;
  reg [15:0] parameter_data_stage1, parameter_data_stage2;
  reg [3:0] parameter_count_stage1, parameter_count_stage2;
  reg encode_start_stage1, encode_start_stage2;
  reg busy_stage1, busy_stage2;
  reg valid_stage1, valid_stage2, valid_stage3;
  
  // Write FSM states
  localparam [1:0] WRITE_IDLE = 2'd0,
                   WRITE_ADDR = 2'd1,
                   WRITE_DATA = 2'd2,
                   WRITE_RESP = 2'd3;
  
  // Read FSM states
  localparam [1:0] READ_IDLE = 2'd0,
                   READ_ADDR = 2'd1,
                   READ_DATA = 2'd2;
  
  reg [1:0] write_state;
  reg [1:0] read_state;
  
  // Write FSM
  always @(posedge ACLK or negedge ARESETn) begin
    if (!ARESETn) begin
      write_state <= WRITE_IDLE;
      AWREADY <= 1'b0;
      WREADY <= 1'b0;
      BVALID <= 1'b0;
      BRESP <= 2'b00;
      cmd_type_stage1 <= 8'd0;
      parameter_data_stage1 <= 16'd0;
      parameter_count_stage1 <= 4'd0;
      encode_start_stage1 <= 1'b0;
    end else begin
      case (write_state)
        WRITE_IDLE: begin
          AWREADY <= 1'b1;
          if (AWVALID) begin
            write_state <= WRITE_DATA;
            AWREADY <= 1'b0;
          end
        end
        
        WRITE_DATA: begin
          WREADY <= 1'b1;
          if (WVALID) begin
            case (AWADDR[7:0])
              8'h00: cmd_type_stage1 <= WDATA[7:0];
              8'h04: parameter_data_stage1 <= WDATA[15:0];
              8'h08: parameter_count_stage1 <= WDATA[3:0];
              8'h0C: encode_start_stage1 <= WDATA[0];
            endcase
            WREADY <= 1'b0;
            write_state <= WRITE_RESP;
          end
        end
        
        WRITE_RESP: begin
          BVALID <= 1'b1;
          BRESP <= 2'b00;
          if (BREADY) begin
            BVALID <= 1'b0;
            write_state <= WRITE_IDLE;
          end
        end
      endcase
    end
  end
  
  // Read FSM
  always @(posedge ACLK or negedge ARESETn) begin
    if (!ARESETn) begin
      read_state <= READ_IDLE;
      ARREADY <= 1'b0;
      RVALID <= 1'b0;
      RRESP <= 2'b00;
      RDATA <= 32'd0;
    end else begin
      case (read_state)
        READ_IDLE: begin
          ARREADY <= 1'b1;
          if (ARVALID) begin
            read_state <= READ_DATA;
            ARREADY <= 1'b0;
          end
        end
        
        READ_DATA: begin
          RVALID <= 1'b1;
          RRESP <= 2'b00;
          case (ARADDR[7:0])
            8'h00: RDATA <= {24'd0, cmd_type_stage2};
            8'h04: RDATA <= {16'd0, parameter_data_stage2};
            8'h08: RDATA <= {28'd0, parameter_count_stage2};
            8'h0C: RDATA <= {31'd0, encode_start_stage2};
            8'h10: RDATA <= packet_data;
            8'h14: RDATA <= {31'd0, packet_ready};
            8'h18: RDATA <= {31'd0, busy};
          endcase
          if (RREADY) begin
            RVALID <= 1'b0;
            read_state <= READ_IDLE;
          end
        end
      endcase
    end
  end
  
  // Pipeline Stage 1: Input Register
  always @(posedge ACLK or negedge ARESETn) begin
    if (!ARESETn) begin
      state_stage1 <= 4'd0;
      param_idx_stage1 <= 4'd0;
      cmd_type_stage2 <= 8'd0;
      parameter_data_stage2 <= 16'd0;
      parameter_count_stage2 <= 4'd0;
      encode_start_stage2 <= 1'b0;
      busy_stage1 <= 1'b0;
      valid_stage1 <= 1'b0;
    end else begin
      cmd_type_stage2 <= cmd_type_stage1;
      parameter_data_stage2 <= parameter_data_stage1;
      parameter_count_stage2 <= parameter_count_stage1;
      encode_start_stage2 <= encode_start_stage1;
      
      if (encode_start_stage1 && !busy) begin
        state_stage1 <= 4'd1;
        param_idx_stage1 <= 4'd0;
        busy_stage1 <= 1'b1;
        valid_stage1 <= 1'b1;
      end else if (busy_stage1) begin
        state_stage1 <= state_stage1 + 1'b1;
        param_idx_stage1 <= param_idx_stage1 + 1'b1;
        valid_stage1 <= 1'b1;
      end else begin
        valid_stage1 <= 1'b0;
      end
    end
  end
  
  // Pipeline Stage 2: Computation
  always @(posedge ACLK or negedge ARESETn) begin
    if (!ARESETn) begin
      state_stage2 <= 4'd0;
      param_idx_stage2 <= 4'd0;
      busy_stage2 <= 1'b0;
      valid_stage2 <= 1'b0;
    end else begin
      state_stage2 <= state_stage1;
      param_idx_stage2 <= param_idx_stage1;
      busy_stage2 <= busy_stage1;
      valid_stage2 <= valid_stage1;
    end
  end
  
  // Pipeline Stage 3: Output Register
  always @(posedge ACLK or negedge ARESETn) begin
    if (!ARESETn) begin
      state_stage3 <= 4'd0;
      packet_data <= 32'h0;
      packet_ready <= 1'b0;
      busy <= 1'b0;
      valid_stage3 <= 1'b0;
    end else begin
      state_stage3 <= state_stage2;
      valid_stage3 <= valid_stage2;
      
      if (valid_stage2) begin
        if (state_stage2 == 4'd1) begin
          packet_data[7:0] <= cmd_type_stage2;
          packet_data[15:8] <= 8'h00;
          packet_data[31:16] <= (parameter_count_stage2 > 0) ? 
                               {8'h00, parameter_data_stage2[7:0]} : 16'h0000;
          packet_ready <= 1'b1;
          busy <= busy_stage2;
        end else begin
          packet_ready <= 1'b0;
          if (state_stage2 == 4'd5) begin
            busy <= 1'b0;
          end else begin
            busy <= busy_stage2;
          end
        end
      end else begin
        packet_ready <= 1'b0;
        busy <= 1'b0;
      end
    end
  end

endmodule
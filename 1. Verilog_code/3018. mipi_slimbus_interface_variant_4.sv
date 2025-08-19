//SystemVerilog
module mipi_slimbus_interface (
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
  
  // Original Interface Signals
  input wire data_in,
  input wire clock_in,
  input wire [7:0] device_id,
  output reg data_out,
  output reg frame_sync
);

  localparam SYNC = 2'b00, HEADER = 2'b01, DATA = 2'b10, CRC = 2'b11;
  reg [1:0] state;
  reg [7:0] bit_counter;
  reg [9:0] frame_counter;
  reg [31:0] received_data;
  reg data_valid;
  
  // AXI4-Lite State Machine
  localparam IDLE = 2'b00, WRITE = 2'b01, READ = 2'b10;
  reg [1:0] axi_state;
  
  // Register Map
  reg [31:0] control_reg;
  reg [31:0] status_reg;
  reg [31:0] data_reg;
  
  // Write Channel FSM
  always @(posedge aclk or negedge aresetn) begin
    if (!aresetn) begin
      axi_state <= IDLE;
      awready <= 1'b0;
      wready <= 1'b0;
      bvalid <= 1'b0;
      bresp <= 2'b00;
    end else begin
      case (axi_state)
        IDLE: begin
          if (awvalid && wvalid) begin
            axi_state <= WRITE;
            awready <= 1'b1;
            wready <= 1'b1;
          end
        end
        
        WRITE: begin
          awready <= 1'b0;
          wready <= 1'b0;
          case (awaddr[7:0])
            8'h00: control_reg <= wdata;
            8'h04: data_reg <= wdata;
            default: bresp <= 2'b10; // SLVERR
          endcase
          bvalid <= 1'b1;
          axi_state <= IDLE;
        end
      endcase
    end
  end
  
  // Read Channel FSM
  always @(posedge aclk or negedge aresetn) begin
    if (!aresetn) begin
      arready <= 1'b0;
      rvalid <= 1'b0;
      rresp <= 2'b00;
    end else begin
      if (arvalid && !rvalid) begin
        arready <= 1'b1;
        case (araddr[7:0])
          8'h00: rdata <= control_reg;
          8'h04: rdata <= data_reg;
          8'h08: rdata <= status_reg;
          default: rresp <= 2'b10; // SLVERR
        endcase
        rvalid <= 1'b1;
      end else if (rready) begin
        arready <= 1'b0;
        rvalid <= 1'b0;
      end
    end
  end
  
  // Original Protocol Logic
  always @(posedge clock_in or negedge aresetn) begin
    if (!aresetn) begin
      state <= SYNC;
      bit_counter <= 8'd0;
      frame_counter <= 10'd0;
      data_valid <= 1'b0;
      received_data <= 32'd0;
      data_out <= 1'b0;
      frame_sync <= 1'b0;
    end else begin
      case (state)
        SYNC: begin
          data_valid <= 1'b0;
          if (data_in && frame_counter == 10'd511) begin
            state <= HEADER;
            frame_sync <= 1'b1;
          end else begin
            frame_sync <= 1'b0;
          end
        end
        
        HEADER: begin
          frame_sync <= 1'b0;
          if (bit_counter < 8'd15) begin
            bit_counter <= bit_counter + 1'b1;
            if (bit_counter < 8) begin
              if (bit_counter == 7 && received_data[7:0] != device_id) begin
                state <= SYNC;
                bit_counter <= 8'd0;
              end
            end
          end else begin
            bit_counter <= 8'd0;
            state <= DATA;
          end
        end
        
        DATA: begin
          if (bit_counter < 8'd31) begin
            bit_counter <= bit_counter + 1'b1;
            received_data <= {received_data[30:0], data_in};
          end else begin
            bit_counter <= 8'd0;
            state <= CRC;
          end
        end
        
        CRC: begin
          if (bit_counter < 8'd7) begin
            bit_counter <= bit_counter + 1'b1;
            if (bit_counter == 7) begin
              data_valid <= 1'b1;
              state <= SYNC;
            end
          end else begin
            bit_counter <= 8'd0;
            state <= SYNC;
          end
        end
        
        default: state <= SYNC;
      endcase
      
      frame_counter <= (frame_counter == 10'd511) ? 10'd0 : frame_counter + 1'b1;
    end
  end
  
  // Update status register
  always @(posedge aclk or negedge aresetn) begin
    if (!aresetn) begin
      status_reg <= 32'd0;
    end else begin
      status_reg <= {30'd0, data_valid, frame_sync};
    end
  end
  
  // Data output logic
  always @(posedge aclk or negedge aresetn) begin
    if (!aresetn) begin
      data_out <= 1'b0;
    end else if (state == DATA) begin
      data_out <= received_data[31];
    end else begin
      data_out <= 1'b0;
    end
  end
endmodule
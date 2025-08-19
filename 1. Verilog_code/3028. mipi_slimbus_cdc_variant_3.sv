//SystemVerilog
module mipi_slimbus_cdc_axi4lite (
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
  input wire rready
);

  // Internal signals
  reg [31:0] fifo [0:3];
  reg [1:0] wr_ptr_src;
  reg [1:0] wr_ptr_gray;
  reg [1:0] rd_ptr_dst;
  reg [1:0] rd_ptr_gray;
  reg [1:0] wr_ptr_sync;
  reg [1:0] rd_ptr_sync;
  
  // State machine states
  localparam IDLE = 2'b00;
  localparam WRITE = 2'b01;
  localparam READ = 2'b10;
  reg [1:0] state;
  
  // Reset logic for write state machine
  always @(posedge aclk or negedge aresetn) begin
    if (!aresetn) begin
      state <= IDLE;
    end
  end
  
  // Write state machine transitions
  always @(posedge aclk) begin
    if (aresetn) begin
      case (state)
        IDLE: begin
          if (awvalid && awready) begin
            state <= WRITE;
          end
        end
        WRITE: begin
          if (wvalid && wready) begin
            state <= IDLE;
          end
        end
        default: state <= IDLE;
      endcase
    end
  end
  
  // Write address ready control
  always @(posedge aclk or negedge aresetn) begin
    if (!aresetn) begin
      awready <= 1'b0;
    end else begin
      case (state)
        IDLE: begin
          awready <= 1'b1;
          if (awvalid && awready) begin
            awready <= 1'b0;
          end
        end
        default: awready <= 1'b0;
      endcase
    end
  end
  
  // Write data ready control
  always @(posedge aclk or negedge aresetn) begin
    if (!aresetn) begin
      wready <= 1'b0;
    end else begin
      case (state)
        WRITE: begin
          wready <= 1'b1;
          if (wvalid && wready) begin
            wready <= 1'b0;
          end
        end
        default: wready <= 1'b0;
      endcase
    end
  end
  
  // Write response control
  always @(posedge aclk or negedge aresetn) begin
    if (!aresetn) begin
      bvalid <= 1'b0;
      bresp <= 2'b00;
    end else begin
      if (state == WRITE && wvalid && wready) begin
        bvalid <= 1'b1;
      end else if (bvalid && bready) begin
        bvalid <= 1'b0;
      end
    end
  end
  
  // FIFO write pointer and data
  always @(posedge aclk) begin
    if (aresetn && state == WRITE && wvalid && wready) begin
      fifo[wr_ptr_src] <= wdata;
      wr_ptr_src <= wr_ptr_src + 1'b1;
      wr_ptr_gray <= wr_ptr_src ^ (wr_ptr_src >> 1);
    end
  end
  
  // Read address ready control
  always @(posedge aclk or negedge aresetn) begin
    if (!aresetn) begin
      arready <= 1'b0;
    end else begin
      if (arvalid && arready) begin
        arready <= 1'b0;
      end else if (rvalid && rready) begin
        arready <= 1'b1;
      end else if (!rvalid) begin
        arready <= 1'b1;
      end
    end
  end
  
  // Read data and response control
  always @(posedge aclk or negedge aresetn) begin
    if (!aresetn) begin
      rvalid <= 1'b0;
      rresp <= 2'b00;
    end else begin
      if (arvalid && arready) begin
        rvalid <= 1'b1;
      end else if (rvalid && rready) begin
        rvalid <= 1'b0;
      end
    end
  end
  
  // Read data assignment
  always @(posedge aclk) begin
    if (aresetn && arvalid && arready) begin
      rdata <= fifo[rd_ptr_dst];
      rd_ptr_dst <= rd_ptr_dst + 1'b1;
      rd_ptr_gray <= rd_ptr_dst ^ (rd_ptr_dst >> 1);
    end
  end
  
  // Pointer synchronization
  always @(posedge aclk or negedge aresetn) begin
    if (!aresetn) begin
      wr_ptr_sync <= 2'd0;
      rd_ptr_sync <= 2'd0;
    end else begin
      wr_ptr_sync <= wr_ptr_gray;
      rd_ptr_sync <= rd_ptr_gray;
    end
  end

endmodule
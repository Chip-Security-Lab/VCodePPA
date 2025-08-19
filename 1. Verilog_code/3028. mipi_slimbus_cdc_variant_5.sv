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
  input wire rready,
  
  // Internal signals
  input wire src_clk,
  input wire dst_clk
);

  // Dual-port synchronization FIFO
  reg [31:0] fifo [0:3];
  reg [1:0] wr_ptr_src, rd_ptr_dst;
  reg [1:0] wr_ptr_gray, rd_ptr_gray;
  reg [1:0] wr_ptr_sync, rd_ptr_sync;
  
  // AXI4-Lite control registers
  reg [31:0] control_reg;
  reg [31:0] status_reg;
  reg [31:0] data_reg;
  
  // Gray code conversion functions
  function [1:0] bin2gray;
    input [1:0] bin;
    begin
      bin2gray = bin ^ (bin >> 1);
    end
  endfunction
  
  function [1:0] gray2bin;
    input [1:0] gray;
    begin
      gray2bin = gray ^ (gray >> 1);
    end
  endfunction
  
  // Write FSM
  reg [1:0] write_state;
  localparam WRITE_IDLE = 2'd0;
  localparam WRITE_ADDR = 2'd1;
  localparam WRITE_DATA = 2'd2;
  localparam WRITE_RESP = 2'd3;
  
  // Read FSM
  reg [1:0] read_state;
  localparam READ_IDLE = 2'd0;
  localparam READ_ADDR = 2'd1;
  localparam READ_DATA = 2'd2;
  
  // Write FSM logic
  always @(posedge aclk or negedge aresetn) begin
    if (!aresetn) begin
      write_state <= WRITE_IDLE;
      awready <= 1'b0;
      wready <= 1'b0;
      bvalid <= 1'b0;
      bresp <= 2'b00;
      control_reg <= 32'd0;
      data_reg <= 32'd0;
    end else begin
      case (write_state)
        WRITE_IDLE: begin
          awready <= 1'b1;
          if (awvalid) begin
            write_state <= WRITE_DATA;
            awready <= 1'b0;
          end
        end
        WRITE_DATA: begin
          wready <= 1'b1;
          if (wvalid) begin
            case (awaddr[7:0])
              8'h00: control_reg <= wdata;
              8'h04: data_reg <= wdata;
              default: bresp <= 2'b10; // SLVERR
            endcase
            write_state <= WRITE_RESP;
            wready <= 1'b0;
          end
        end
        WRITE_RESP: begin
          bvalid <= 1'b1;
          if (bready) begin
            write_state <= WRITE_IDLE;
            bvalid <= 1'b0;
          end
        end
      endcase
    end
  end
  
  // Read FSM logic
  always @(posedge aclk or negedge aresetn) begin
    if (!aresetn) begin
      read_state <= READ_IDLE;
      arready <= 1'b0;
      rvalid <= 1'b0;
      rresp <= 2'b00;
      rdata <= 32'd0;
    end else begin
      case (read_state)
        READ_IDLE: begin
          arready <= 1'b1;
          if (arvalid) begin
            read_state <= READ_DATA;
            arready <= 1'b0;
          end
        end
        READ_DATA: begin
          rvalid <= 1'b1;
          case (araddr[7:0])
            8'h00: rdata <= control_reg;
            8'h04: rdata <= data_reg;
            8'h08: rdata <= status_reg;
            default: rresp <= 2'b10; // SLVERR
          endcase
          if (rready) begin
            read_state <= READ_IDLE;
            rvalid <= 1'b0;
          end
        end
      endcase
    end
  end
  
  // Source domain logic
  always @(posedge src_clk or negedge aresetn) begin
    if (!aresetn) begin
      wr_ptr_src <= 2'd0;
      wr_ptr_gray <= 2'd0;
    end else if (control_reg[0]) begin // Write enable from control register
      fifo[wr_ptr_src] <= data_reg;
      wr_ptr_src <= wr_ptr_src + 1'b1;
      wr_ptr_gray <= bin2gray(wr_ptr_src + 1'b1);
    end
  end
  
  // Destination domain logic
  always @(posedge dst_clk or negedge aresetn) begin
    if (!aresetn) begin
      rd_ptr_dst <= 2'd0;
      rd_ptr_gray <= 2'd0;
      status_reg <= 32'd0;
    end else begin
      rd_ptr_sync <= wr_ptr_gray;
      rd_ptr_dst <= gray2bin(rd_ptr_sync);
      if (rd_ptr_dst != wr_ptr_sync) begin
        status_reg <= fifo[rd_ptr_dst];
      end
    end
  end

endmodule
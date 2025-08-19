//SystemVerilog
// Top level module
module mipi_protocol_converter_axi4lite (
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
  
  // Protocol Interface
  output reg [31:0] dst_data,
  output reg dst_valid,
  output reg conversion_error
);

  // Internal signals
  wire [31:0] src_data;
  wire src_valid;
  wire [3:0] src_protocol;
  wire [3:0] dst_protocol;
  wire [7:0] converted_header;
  wire header_valid;

  // Instantiate submodules
  axi_write_ctrl write_ctrl (
    .ACLK(ACLK),
    .ARESETn(ARESETn),
    .AWADDR(AWADDR),
    .AWVALID(AWVALID),
    .AWREADY(AWREADY),
    .WDATA(WDATA),
    .WVALID(WVALID),
    .WREADY(WREADY),
    .BVALID(BVALID),
    .BREADY(BREADY),
    .BRESP(BRESP),
    .src_data(src_data),
    .src_valid(src_valid),
    .src_protocol(src_protocol),
    .dst_protocol(dst_protocol)
  );

  axi_read_ctrl read_ctrl (
    .ACLK(ACLK),
    .ARESETn(ARESETn),
    .ARADDR(ARADDR),
    .ARVALID(ARVALID),
    .ARREADY(ARREADY),
    .RREADY(RREADY),
    .RVALID(RVALID),
    .RRESP(RRESP),
    .RDATA(RDATA),
    .dst_data(dst_data),
    .dst_valid(dst_valid),
    .conversion_error(conversion_error)
  );

  protocol_converter conv (
    .ACLK(ACLK),
    .ARESETn(ARESETn),
    .src_data(src_data),
    .src_valid(src_valid),
    .src_protocol(src_protocol),
    .dst_protocol(dst_protocol),
    .dst_data(dst_data),
    .dst_valid(dst_valid),
    .conversion_error(conversion_error)
  );

endmodule

// Write control submodule
module axi_write_ctrl (
  input wire ACLK,
  input wire ARESETn,
  input wire [31:0] AWADDR,
  input wire AWVALID,
  output reg AWREADY,
  input wire [31:0] WDATA,
  input wire WVALID,
  output reg WREADY,
  output reg BVALID,
  input wire BREADY,
  output reg [1:0] BRESP,
  output reg [31:0] src_data,
  output reg src_valid,
  output reg [3:0] src_protocol,
  output reg [3:0] dst_protocol
);

  localparam IDLE = 2'd0;
  localparam WRITE = 2'd1;
  
  reg [1:0] state;

  always @(posedge ACLK or negedge ARESETn) begin
    if (!ARESETn) begin
      state <= IDLE;
      AWREADY <= 1'b0;
      WREADY <= 1'b0;
      BVALID <= 1'b0;
      BRESP <= 2'b00;
      src_data <= 32'h0;
      src_valid <= 1'b0;
      src_protocol <= 4'h0;
      dst_protocol <= 4'h0;
    end else begin
      case (state)
        IDLE: begin
          AWREADY <= 1'b1;
          WREADY <= 1'b0;
          BVALID <= 1'b0;
          if (AWVALID) begin
            state <= WRITE;
            WREADY <= 1'b1;
          end
        end
        WRITE: begin
          if (WVALID) begin
            case (AWADDR[7:0])
              8'h00: src_data <= WDATA;
              8'h04: src_valid <= WDATA[0];
              8'h08: src_protocol <= WDATA[3:0];
              8'h0C: dst_protocol <= WDATA[3:0];
            endcase
            WREADY <= 1'b0;
            BVALID <= 1'b1;
            BRESP <= 2'b00;
            state <= IDLE;
          end
        end
      endcase
    end
  end
endmodule

// Read control submodule
module axi_read_ctrl (
  input wire ACLK,
  input wire ARESETn,
  input wire [31:0] ARADDR,
  input wire ARVALID,
  output reg ARREADY,
  input wire RREADY,
  output reg RVALID,
  output reg [1:0] RRESP,
  output reg [31:0] RDATA,
  input wire [31:0] dst_data,
  input wire dst_valid,
  input wire conversion_error
);

  always @(posedge ACLK or negedge ARESETn) begin
    if (!ARESETn) begin
      ARREADY <= 1'b0;
      RVALID <= 1'b0;
      RRESP <= 2'b00;
      RDATA <= 32'h0;
    end else begin
      ARREADY <= 1'b1;
      if (ARVALID) begin
        case (ARADDR[7:0])
          8'h10: RDATA <= dst_data;
          8'h14: RDATA <= {31'h0, dst_valid};
          8'h18: RDATA <= {31'h0, conversion_error};
          default: RDATA <= 32'h0;
        endcase
        RVALID <= 1'b1;
        RRESP <= 2'b00;
      end
      if (RREADY) begin
        RVALID <= 1'b0;
      end
    end
  end
endmodule

// Protocol converter submodule
module protocol_converter (
  input wire ACLK,
  input wire ARESETn,
  input wire [31:0] src_data,
  input wire src_valid,
  input wire [3:0] src_protocol,
  input wire [3:0] dst_protocol,
  output reg [31:0] dst_data,
  output reg dst_valid,
  output reg conversion_error
);

  reg [3:0] state;
  reg [7:0] header_type;

  function [7:0] convert_header;
    input [7:0] src_header;
    input [3:0] src_proto;
    input [3:0] dst_proto;
    begin
      if (src_proto == 4'd0 && dst_proto == 4'd1) begin
        case (src_header)
          8'h00: convert_header = 8'h01;
          8'h01: convert_header = 8'h02;
          8'h02: convert_header = 8'h03;
          8'h03: convert_header = 8'h04;
          8'h1A: convert_header = 8'h3E;
          default: convert_header = 8'hFF;
        endcase
      end else if (src_proto == 4'd1 && dst_proto == 4'd0) begin
        case (src_header)
          8'h01: convert_header = 8'h00;
          8'h02: convert_header = 8'h01;
          8'h03: convert_header = 8'h02;
          8'h04: convert_header = 8'h03;
          8'h3E: convert_header = 8'h1A;
          default: convert_header = 8'hFF;
        endcase
      end else convert_header = 8'hFF;
    end
  endfunction

  always @(posedge ACLK or negedge ARESETn) begin
    if (!ARESETn) begin
      state <= 4'd0;
      conversion_error <= 1'b0;
      dst_valid <= 1'b0;
    end else if (src_valid) begin
      if (state == 4'd0) begin
        header_type <= src_data[7:0];
        if (convert_header(src_data[7:0], src_protocol, dst_protocol) == 8'hFF) begin
          conversion_error <= 1'b1;
        end else begin
          dst_data <= {src_data[31:8], convert_header(src_data[7:0], src_protocol, dst_protocol)};
          dst_valid <= 1'b1;
          state <= 4'd1;
        end
      end else begin
        dst_data <= src_data;
        dst_valid <= 1'b1;
      end
    end else dst_valid <= 1'b0;
  end
endmodule
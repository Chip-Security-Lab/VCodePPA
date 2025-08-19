//SystemVerilog
module rng_async_mix_7_axi4lite #(
    parameter ADDR_WIDTH = 4
)(
    input                  axi_aclk,
    input                  axi_aresetn,

    // AXI4-Lite Write Address Channel
    input  [ADDR_WIDTH-1:0] s_axi_awaddr,
    input                   s_axi_awvalid,
    output                  s_axi_awready,

    // AXI4-Lite Write Data Channel
    input  [7:0]            s_axi_wdata,
    input  [0:0]            s_axi_wstrb,
    input                   s_axi_wvalid,
    output                  s_axi_wready,

    // AXI4-Lite Write Response Channel
    output [1:0]            s_axi_bresp,
    output                  s_axi_bvalid,
    input                   s_axi_bready,

    // AXI4-Lite Read Address Channel
    input  [ADDR_WIDTH-1:0] s_axi_araddr,
    input                   s_axi_arvalid,
    output                  s_axi_arready,

    // AXI4-Lite Read Data Channel
    output [7:0]            s_axi_rdata,
    output [1:0]            s_axi_rresp,
    output                  s_axi_rvalid,
    input                   s_axi_rready
);

// Internal registers for AXI4-Lite handshaking and data
reg  axi_awready_reg, axi_wready_reg, axi_bvalid_reg, axi_arready_reg, axi_rvalid_reg;
reg  [1:0] axi_bresp_reg, axi_rresp_reg;
reg  [7:0] axi_rdata_reg;
reg  [7:0] reg_in_cnt;
wire [7:0] reg_out_rand;
reg  [ADDR_WIDTH-1:0] awaddr_reg, araddr_reg;

// Write address handshake
always @(posedge axi_aclk) begin
    if (~axi_aresetn) begin
        axi_awready_reg <= 1'b0;
        awaddr_reg      <= {ADDR_WIDTH{1'b0}};
    end else if (~axi_awready_reg && s_axi_awvalid) begin
        axi_awready_reg <= 1'b1;
        awaddr_reg      <= s_axi_awaddr;
    end else begin
        axi_awready_reg <= 1'b0;
    end
end

assign s_axi_awready = axi_awready_reg;

// Write data handshake
always @(posedge axi_aclk) begin
    if (~axi_aresetn) begin
        axi_wready_reg <= 1'b0;
    end else if (~axi_wready_reg && s_axi_wvalid) begin
        axi_wready_reg <= 1'b1;
    end else begin
        axi_wready_reg <= 1'b0;
    end
end

assign s_axi_wready = axi_wready_reg;

// Write logic
always @(posedge axi_aclk) begin
    if (~axi_aresetn) begin
        reg_in_cnt <= 8'h00;
    end else if (axi_awready_reg && s_axi_awvalid && axi_wready_reg && s_axi_wvalid) begin
        if (awaddr_reg[ADDR_WIDTH-1:0] == 0) begin
            // Only byte 0 is valid
            if (s_axi_wstrb[0])
                reg_in_cnt <= s_axi_wdata;
        end
    end
end

// Write response
always @(posedge axi_aclk) begin
    if (~axi_aresetn) begin
        axi_bvalid_reg <= 1'b0;
        axi_bresp_reg  <= 2'b00;
    end else if (axi_awready_reg && s_axi_awvalid && axi_wready_reg && s_axi_wvalid && ~axi_bvalid_reg) begin
        axi_bvalid_reg <= 1'b1;
        axi_bresp_reg  <= 2'b00;
    end else if (s_axi_bready && axi_bvalid_reg) begin
        axi_bvalid_reg <= 1'b0;
    end
end

assign s_axi_bvalid = axi_bvalid_reg;
assign s_axi_bresp  = axi_bresp_reg;

// Read address handshake
always @(posedge axi_aclk) begin
    if (~axi_aresetn) begin
        axi_arready_reg <= 1'b0;
        araddr_reg      <= {ADDR_WIDTH{1'b0}};
    end else if (~axi_arready_reg && s_axi_arvalid) begin
        axi_arready_reg <= 1'b1;
        araddr_reg      <= s_axi_araddr;
    end else begin
        axi_arready_reg <= 1'b0;
    end
end

assign s_axi_arready = axi_arready_reg;

// Read data logic
always @(posedge axi_aclk) begin
    if (~axi_aresetn) begin
        axi_rvalid_reg <= 1'b0;
        axi_rresp_reg  <= 2'b00;
        axi_rdata_reg  <= 8'h00;
    end else if (axi_arready_reg && s_axi_arvalid && ~axi_rvalid_reg) begin
        axi_rvalid_reg <= 1'b1;
        axi_rresp_reg  <= 2'b00;
        case (araddr_reg[ADDR_WIDTH-1:0])
            0: axi_rdata_reg <= reg_in_cnt;
            4: axi_rdata_reg <= reg_out_rand;
            default: axi_rdata_reg <= 8'h00;
        endcase
    end else if (axi_rvalid_reg && s_axi_rready) begin
        axi_rvalid_reg <= 1'b0;
    end
end

assign s_axi_rvalid = axi_rvalid_reg;
assign s_axi_rresp  = axi_rresp_reg;
assign s_axi_rdata  = axi_rdata_reg;

// Core logic
assign reg_out_rand = {reg_in_cnt[3:0] ^ reg_in_cnt[7:4],
                       (reg_in_cnt[1:0] + reg_in_cnt[3:2]) ^ reg_in_cnt[5:4]};

endmodule
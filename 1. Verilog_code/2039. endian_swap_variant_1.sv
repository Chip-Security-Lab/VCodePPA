//SystemVerilog
module endian_swap_axi4lite #(
    parameter ADDR_WIDTH = 4
)(
    input wire                  ACLK,
    input wire                  ARESETN,
    // Write address channel
    input wire [ADDR_WIDTH-1:0] S_AXI_AWADDR,
    input wire                  S_AXI_AWVALID,
    output wire                 S_AXI_AWREADY,
    // Write data channel
    input wire [31:0]           S_AXI_WDATA,
    input wire [3:0]            S_AXI_WSTRB,
    input wire                  S_AXI_WVALID,
    output wire                 S_AXI_WREADY,
    // Write response channel
    output wire [1:0]           S_AXI_BRESP,
    output wire                 S_AXI_BVALID,
    input wire                  S_AXI_BREADY,
    // Read address channel
    input wire [ADDR_WIDTH-1:0] S_AXI_ARADDR,
    input wire                  S_AXI_ARVALID,
    output wire                 S_AXI_ARREADY,
    // Read data channel
    output wire [31:0]          S_AXI_RDATA,
    output wire [1:0]           S_AXI_RRESP,
    output wire                 S_AXI_RVALID,
    input wire                  S_AXI_RREADY
);

    // Internal registers
    reg [31:0] reg_data_in;
    reg        awready_reg, wready_reg, bvalid_reg;
    reg [1:0]  bresp_reg;
    reg        arready_reg, rvalid_reg;
    reg [31:0] rdata_reg;
    reg [1:0]  rresp_reg;

    // Write address handshake
    wire aw_hs = S_AXI_AWVALID & awready_reg;
    // Write data handshake
    wire w_hs  = S_AXI_WVALID  & wready_reg;
    // Read address handshake
    wire ar_hs = S_AXI_ARVALID & arready_reg;

    // Write response
    assign S_AXI_BRESP  = bresp_reg;
    assign S_AXI_BVALID = bvalid_reg;
    // Write address/data handshake ready
    assign S_AXI_AWREADY = awready_reg;
    assign S_AXI_WREADY  = wready_reg;
    // Read address handshake ready
    assign S_AXI_ARREADY = arready_reg;
    // Read data channel
    assign S_AXI_RDATA  = rdata_reg;
    assign S_AXI_RRESP  = rresp_reg;
    assign S_AXI_RVALID = rvalid_reg;

    // Address decoding (simple mapping: 0x0 for input, 0x4 for output)
    localparam ADDR_DATA_IN  = 4'h0;
    localparam ADDR_DATA_OUT = 4'h4;

    // Unified always block for all registers
    always @(posedge ACLK or negedge ARESETN) begin
        if (!ARESETN) begin
            awready_reg <= 1'b1;
            wready_reg  <= 1'b1;
            bvalid_reg  <= 1'b0;
            bresp_reg   <= 2'b00;
            reg_data_in <= 32'b0;
            arready_reg <= 1'b1;
            rvalid_reg  <= 1'b0;
            rdata_reg   <= 32'b0;
            rresp_reg   <= 2'b00;
        end else begin
            // Write address ready
            if (aw_hs)
                awready_reg <= 1'b0;
            else if (bvalid_reg && S_AXI_BREADY)
                awready_reg <= 1'b1;

            // Write data ready
            if (w_hs)
                wready_reg <= 1'b0;
            else if (bvalid_reg && S_AXI_BREADY)
                wready_reg <= 1'b1;

            // Write response logic
            if (aw_hs && w_hs) begin
                bvalid_reg <= 1'b1;
                bresp_reg  <= 2'b00; // OKAY
            end else if (bvalid_reg && S_AXI_BREADY) begin
                bvalid_reg <= 1'b0;
            end

            // Write operation (only to reg_data_in, at ADDR_DATA_IN)
            if (aw_hs && w_hs) begin
                if (S_AXI_AWADDR[ADDR_WIDTH-1:0] == ADDR_DATA_IN) begin
                    reg_data_in[7:0]   <= S_AXI_WSTRB[0] ? S_AXI_WDATA[7:0]   : reg_data_in[7:0];
                    reg_data_in[15:8]  <= S_AXI_WSTRB[1] ? S_AXI_WDATA[15:8]  : reg_data_in[15:8];
                    reg_data_in[23:16] <= S_AXI_WSTRB[2] ? S_AXI_WDATA[23:16] : reg_data_in[23:16];
                    reg_data_in[31:24] <= S_AXI_WSTRB[3] ? S_AXI_WDATA[31:24] : reg_data_in[31:24];
                end
            end

            // Read address ready logic
            if (ar_hs)
                arready_reg <= 1'b0;
            else if (rvalid_reg && S_AXI_RREADY)
                arready_reg <= 1'b1;

            // Read data logic
            if (ar_hs) begin
                rvalid_reg <= 1'b1;
                if (S_AXI_ARADDR[ADDR_WIDTH-1:0] == ADDR_DATA_IN)
                    rdata_reg <= reg_data_in;
                else if (S_AXI_ARADDR[ADDR_WIDTH-1:0] == ADDR_DATA_OUT)
                    rdata_reg <= {reg_data_in[7:0], reg_data_in[15:8], reg_data_in[23:16], reg_data_in[31:24]};
                else
                    rdata_reg <= 32'hDEADBEEF;
                rresp_reg <= 2'b00;
            end else if (rvalid_reg && S_AXI_RREADY) begin
                rvalid_reg <= 1'b0;
            end
        end
    end

endmodule
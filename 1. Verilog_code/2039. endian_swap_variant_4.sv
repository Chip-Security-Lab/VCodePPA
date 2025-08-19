//SystemVerilog
module endian_swap_axi4lite #
(
    parameter ADDR_WIDTH = 4
)
(
    input                  clk,
    input                  rst_n,
    // AXI4-Lite Write Address Channel
    input  [ADDR_WIDTH-1:0] s_axi_awaddr,
    input                   s_axi_awvalid,
    output                  s_axi_awready,
    // AXI4-Lite Write Data Channel
    input  [31:0]           s_axi_wdata,
    input  [3:0]            s_axi_wstrb,
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
    output [31:0]           s_axi_rdata,
    output [1:0]            s_axi_rresp,
    output                  s_axi_rvalid,
    input                   s_axi_rready
);

    // Internal registers
    reg  [31:0] reg_data_in;
    wire [31:0] swapped_data_out;
    reg         awready_reg, wready_reg, bvalid_reg, arready_reg, rvalid_reg;
    reg  [1:0]  bresp_reg, rresp_reg;
    reg  [31:0] rdata_reg;

    // Address decode (single register at offset 0)
    localparam REG_DATA_IN_ADDR  = 4'h0;
    localparam REG_DATA_OUT_ADDR = 4'h4;

    // Write address handshake
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n)
            awready_reg <= 1'b0;
        else if (!awready_reg && s_axi_awvalid)
            awready_reg <= 1'b1;
        else if (awready_reg && s_axi_wvalid && wready_reg)
            awready_reg <= 1'b0;
    end

    assign s_axi_awready = awready_reg;

    // Write data handshake
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n)
            wready_reg <= 1'b0;
        else if (!wready_reg && s_axi_wvalid)
            wready_reg <= 1'b1;
        else if (wready_reg && s_axi_awvalid && awready_reg)
            wready_reg <= 1'b0;
    end

    assign s_axi_wready = wready_reg;

    // Write register (optimized Boolean expressions)
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n)
            reg_data_in <= 32'b0;
        else if (awready_reg && s_axi_awvalid && wready_reg && s_axi_wvalid) begin
            if (s_axi_awaddr[ADDR_WIDTH-1:0] == REG_DATA_IN_ADDR) begin
                reg_data_in[7:0]   <= (s_axi_wstrb[0]) ? s_axi_wdata[7:0]   : reg_data_in[7:0];
                reg_data_in[15:8]  <= (s_axi_wstrb[1]) ? s_axi_wdata[15:8]  : reg_data_in[15:8];
                reg_data_in[23:16] <= (s_axi_wstrb[2]) ? s_axi_wdata[23:16] : reg_data_in[23:16];
                reg_data_in[31:24] <= (s_axi_wstrb[3]) ? s_axi_wdata[31:24] : reg_data_in[31:24];
            end
        end
    end

    // Write response
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            bvalid_reg <= 1'b0;
            bresp_reg  <= 2'b00;
        end else if (awready_reg && s_axi_awvalid && wready_reg && s_axi_wvalid) begin
            bvalid_reg <= 1'b1;
            bresp_reg  <= 2'b00; // OKAY
        end else if (bvalid_reg && s_axi_bready) begin
            bvalid_reg <= 1'b0;
            bresp_reg  <= 2'b00;
        end
    end

    assign s_axi_bvalid = bvalid_reg;
    assign s_axi_bresp  = bresp_reg;

    // Read address handshake
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n)
            arready_reg <= 1'b0;
        else if (!arready_reg && s_axi_arvalid)
            arready_reg <= 1'b1;
        else if (arready_reg && rvalid_reg && s_axi_rready)
            arready_reg <= 1'b0;
    end

    assign s_axi_arready = arready_reg;

    // Read data logic
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            rvalid_reg <= 1'b0;
            rdata_reg  <= 32'b0;
            rresp_reg  <= 2'b00;
        end else if (arready_reg && s_axi_arvalid) begin
            rvalid_reg <= 1'b1;
            if (s_axi_araddr[ADDR_WIDTH-1:0] == REG_DATA_IN_ADDR)
                rdata_reg <= reg_data_in;
            else if (s_axi_araddr[ADDR_WIDTH-1:0] == REG_DATA_OUT_ADDR)
                rdata_reg <= swapped_data_out;
            else
                rdata_reg <= 32'hDEADBEEF;
            rresp_reg <= 2'b00; // OKAY
        end else if (rvalid_reg && s_axi_rready) begin
            rvalid_reg <= 1'b0;
            rresp_reg  <= 2'b00;
        end
    end

    assign s_axi_rvalid = rvalid_reg;
    assign s_axi_rdata  = rdata_reg;
    assign s_axi_rresp  = rresp_reg;

    // Endian swap logic (optimized Boolean expressions)
    assign swapped_data_out = {reg_data_in[7:0], reg_data_in[15:8], reg_data_in[23:16], reg_data_in[31:24]};

endmodule
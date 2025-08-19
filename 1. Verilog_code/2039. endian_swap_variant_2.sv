//SystemVerilog
module endian_swap_axi4lite #(
    parameter ADDR_WIDTH = 4
)(
    input                   clk,
    input                   rst_n,

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

    // High fanout signal buffers
    reg                     clk_buf1, clk_buf2;
    reg                     s_axi_awvalid_buf1, s_axi_awvalid_buf2;
    reg  [31:0]             s_axi_wdata_buf1, s_axi_wdata_buf2;
    reg  [3:0]              s_axi_wstrb_buf1, s_axi_wstrb_buf2;
    reg                     awready_reg_buf1, awready_reg_buf2;

    // Internal registers
    reg                     awready_reg, wready_reg, bvalid_reg, arready_reg, rvalid_reg;
    reg  [31:0]             data_in_reg;
    reg  [31:0]             data_out_reg;
    reg  [1:0]              bresp_reg, rresp_reg;

    // Buffer for clk (to drive high fanout sequential logic)
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            clk_buf1 <= 1'b0;
            clk_buf2 <= 1'b0;
        end else begin
            clk_buf1 <= 1'b1;
            clk_buf2 <= clk_buf1;
        end
    end

    // Buffer for s_axi_awvalid (to reduce fanout)
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            s_axi_awvalid_buf1 <= 1'b0;
            s_axi_awvalid_buf2 <= 1'b0;
        end else begin
            s_axi_awvalid_buf1 <= s_axi_awvalid;
            s_axi_awvalid_buf2 <= s_axi_awvalid_buf1;
        end
    end

    // Buffer for s_axi_wdata (to reduce fanout)
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            s_axi_wdata_buf1 <= 32'b0;
            s_axi_wdata_buf2 <= 32'b0;
        end else begin
            s_axi_wdata_buf1 <= s_axi_wdata;
            s_axi_wdata_buf2 <= s_axi_wdata_buf1;
        end
    end

    // Buffer for s_axi_wstrb (to reduce fanout)
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            s_axi_wstrb_buf1 <= 4'b0;
            s_axi_wstrb_buf2 <= 4'b0;
        end else begin
            s_axi_wstrb_buf1 <= s_axi_wstrb;
            s_axi_wstrb_buf2 <= s_axi_wstrb_buf1;
        end
    end

    // Buffer for awready_reg (to reduce fanout)
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            awready_reg_buf1 <= 1'b0;
            awready_reg_buf2 <= 1'b0;
        end else begin
            awready_reg_buf1 <= awready_reg;
            awready_reg_buf2 <= awready_reg_buf1;
        end
    end

    // Write address handshake with buffered signals
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n)
            awready_reg <= 1'b0;
        else if (~awready_reg && s_axi_awvalid_buf2)
            awready_reg <= 1'b1;
        else if (awready_reg && s_axi_wvalid && wready_reg)
            awready_reg <= 1'b0;
    end

    // Write data handshake
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n)
            wready_reg <= 1'b0;
        else if (~wready_reg && s_axi_wvalid)
            wready_reg <= 1'b1;
        else if (wready_reg && s_axi_awvalid && awready_reg)
            wready_reg <= 1'b0;
    end

    // Write operation with range check, using buffered signals
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n)
            data_in_reg <= 32'b0;
        else if (awready_reg_buf2 && s_axi_awvalid_buf2 && wready_reg && s_axi_wvalid) begin
            if ((s_axi_awaddr & {{(ADDR_WIDTH-4){1'b0}}, 4'hF}) == 4'h0) begin
                data_in_reg[7:0]   <= s_axi_wstrb_buf2[0] ? s_axi_wdata_buf2[7:0]   : data_in_reg[7:0];
                data_in_reg[15:8]  <= s_axi_wstrb_buf2[1] ? s_axi_wdata_buf2[15:8]  : data_in_reg[15:8];
                data_in_reg[23:16] <= s_axi_wstrb_buf2[2] ? s_axi_wdata_buf2[23:16] : data_in_reg[23:16];
                data_in_reg[31:24] <= s_axi_wstrb_buf2[3] ? s_axi_wdata_buf2[31:24] : data_in_reg[31:24];
            end
        end
    end

    // Write response
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            bvalid_reg <= 1'b0;
            bresp_reg  <= 2'b00;
        end else if (awready_reg_buf2 && s_axi_awvalid_buf2 && wready_reg && s_axi_wvalid) begin
            bvalid_reg <= 1'b1;
            bresp_reg  <= 2'b00;
        end else if (bvalid_reg && s_axi_bready) begin
            bvalid_reg <= 1'b0;
        end
    end

    // Read address handshake
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n)
            arready_reg <= 1'b0;
        else if (~arready_reg && s_axi_arvalid)
            arready_reg <= 1'b1;
        else if (arready_reg && rvalid_reg && s_axi_rready)
            arready_reg <= 1'b0;
    end

    // Read operation with range check
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            data_out_reg <= 32'b0;
            rvalid_reg   <= 1'b0;
            rresp_reg    <= 2'b00;
        end else if (arready_reg && s_axi_arvalid) begin
            if ((s_axi_araddr & {{(ADDR_WIDTH-4){1'b0}}, 4'hF}) == 4'h4) begin
                data_out_reg <= {data_in_reg[7:0], data_in_reg[15:8], data_in_reg[23:16], data_in_reg[31:24]};
            end else begin
                data_out_reg <= 32'b0;
            end
            rvalid_reg <= 1'b1;
            rresp_reg  <= 2'b00;
        end else if (rvalid_reg && s_axi_rready) begin
            rvalid_reg <= 1'b0;
        end
    end

    // AXI4-Lite outputs
    assign s_axi_awready = awready_reg;
    assign s_axi_wready  = wready_reg;
    assign s_axi_bvalid  = bvalid_reg;
    assign s_axi_bresp   = bresp_reg;
    assign s_axi_arready = arready_reg;
    assign s_axi_rvalid  = rvalid_reg;
    assign s_axi_rresp   = rresp_reg;
    assign s_axi_rdata   = data_out_reg;

endmodule
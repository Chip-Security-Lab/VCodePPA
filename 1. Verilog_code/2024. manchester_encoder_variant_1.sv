//SystemVerilog
module manchester_encoder_axi4lite #(
    parameter ADDR_WIDTH = 4,
    parameter DATA_WIDTH = 32
)(
    input                       clk,
    input                       rst_n,
    // AXI4-Lite Write Address Channel
    input       [ADDR_WIDTH-1:0] s_axi_awaddr,
    input                        s_axi_awvalid,
    output reg                   s_axi_awready,
    // AXI4-Lite Write Data Channel
    input       [DATA_WIDTH-1:0] s_axi_wdata,
    input       [(DATA_WIDTH/8)-1:0] s_axi_wstrb,
    input                        s_axi_wvalid,
    output reg                   s_axi_wready,
    // AXI4-Lite Write Response Channel
    output reg  [1:0]            s_axi_bresp,
    output reg                   s_axi_bvalid,
    input                        s_axi_bready,
    // AXI4-Lite Read Address Channel
    input       [ADDR_WIDTH-1:0] s_axi_araddr,
    input                        s_axi_arvalid,
    output reg                   s_axi_arready,
    // AXI4-Lite Read Data Channel
    output reg  [DATA_WIDTH-1:0] s_axi_rdata,
    output reg  [1:0]            s_axi_rresp,
    output reg                   s_axi_rvalid,
    input                        s_axi_rready
);

    // Internal registers for AXI4-Lite
    reg data_in_reg;
    reg encoded_out_reg;
    reg data_reg;

    // Address Map
    localparam ADDR_DATA_IN     = 4'h0; // Write: data_in
    localparam ADDR_ENCODED_OUT = 4'h4; // Read: encoded_out

    // Lookup table for write address decode (write enable)
    wire [1:0] write_addr_lut [0:(1<<ADDR_WIDTH)-1];
    genvar i;
    generate
        for (i = 0; i < (1<<ADDR_WIDTH); i = i + 1) begin : WRITE_ADDR_LUT_GEN
            assign write_addr_lut[i] = (i[ADDR_WIDTH-1:0] == ADDR_DATA_IN) ? 2'b01 : 2'b00;
        end
    endgenerate

    // Lookup table for read address decode (read select)
    wire [1:0] read_addr_lut [0:(1<<ADDR_WIDTH)-1];
    generate
        for (i = 0; i < (1<<ADDR_WIDTH); i = i + 1) begin : READ_ADDR_LUT_GEN
            assign read_addr_lut[i] = (i[ADDR_WIDTH-1:0] == ADDR_DATA_IN) ? 2'b01 :
                                      (i[ADDR_WIDTH-1:0] == ADDR_ENCODED_OUT) ? 2'b10 : 2'b00;
        end
    endgenerate

    // Write FSM using LUT
    reg awvalid_d, wvalid_d;
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            s_axi_awready   <= 1'b0;
            s_axi_wready    <= 1'b0;
            s_axi_bvalid    <= 1'b0;
            s_axi_bresp     <= 2'b00;
            data_in_reg     <= 1'b0;
            awvalid_d       <= 1'b0;
            wvalid_d        <= 1'b0;
        end else begin
            // Registered handshake signals to avoid race
            awvalid_d <= s_axi_awvalid;
            wvalid_d  <= s_axi_wvalid;

            // AWREADY logic
            if (!s_axi_awready && s_axi_awvalid) begin
                s_axi_awready <= 1'b1;
            end else if (s_axi_awready && !s_axi_awvalid) begin
                s_axi_awready <= 1'b0;
            end

            // WREADY logic
            if (!s_axi_wready && s_axi_wvalid) begin
                s_axi_wready <= 1'b1;
            end else if (s_axi_wready && !s_axi_wvalid) begin
                s_axi_wready <= 1'b0;
            end

            // Write response logic using LUT
            if ((s_axi_awready && awvalid_d && s_axi_wready && wvalid_d)) begin
                case (write_addr_lut[s_axi_awaddr])
                    2'b01: begin // Write to data_in
                        data_in_reg <= s_axi_wdata[0];
                        s_axi_bvalid <= 1'b1;
                        s_axi_bresp  <= 2'b00;
                    end
                    default: begin
                        s_axi_bvalid <= 1'b1;
                        s_axi_bresp  <= 2'b00;
                    end
                endcase
            end else if (s_axi_bvalid && s_axi_bready) begin
                s_axi_bvalid <= 1'b0;
            end
        end
    end

    // Read FSM using LUT
    reg arvalid_d, rvalid_d;
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            s_axi_arready   <= 1'b0;
            s_axi_rvalid    <= 1'b0;
            s_axi_rdata     <= {DATA_WIDTH{1'b0}};
            s_axi_rresp     <= 2'b00;
            arvalid_d       <= 1'b0;
            rvalid_d        <= 1'b0;
        end else begin
            // Registered handshake signals to avoid race
            arvalid_d <= s_axi_arvalid;
            rvalid_d  <= s_axi_rvalid;

            // ARREADY logic
            if (!s_axi_arready && s_axi_arvalid) begin
                s_axi_arready <= 1'b1;
            end else if (s_axi_arready && !s_axi_arvalid) begin
                s_axi_arready <= 1'b0;
            end

            // Read response logic using LUT
            if ((s_axi_arready && arvalid_d && !s_axi_rvalid)) begin
                case (read_addr_lut[s_axi_araddr])
                    2'b01: begin // Read data_in
                        s_axi_rdata  <= { {DATA_WIDTH-1{1'b0}}, data_in_reg };
                        s_axi_rvalid <= 1'b1;
                        s_axi_rresp  <= 2'b00;
                    end
                    2'b10: begin // Read encoded_out
                        s_axi_rdata  <= { {DATA_WIDTH-1{1'b0}}, encoded_out_reg };
                        s_axi_rvalid <= 1'b1;
                        s_axi_rresp  <= 2'b00;
                    end
                    default: begin
                        s_axi_rdata  <= {DATA_WIDTH{1'b0}};
                        s_axi_rvalid <= 1'b1;
                        s_axi_rresp  <= 2'b00;
                    end
                endcase
            end else if (s_axi_rvalid && s_axi_rready) begin
                s_axi_rvalid <= 1'b0;
            end
        end
    end

    // Core Manchester Encoder logic
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            data_reg        <= 1'b0;
            encoded_out_reg <= 1'b0;
        end else begin
            data_reg <= data_in_reg;
            if (data_reg)
                encoded_out_reg <= ~encoded_out_reg;
        end
    end

endmodule
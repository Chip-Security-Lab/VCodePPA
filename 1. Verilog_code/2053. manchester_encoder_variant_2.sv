//SystemVerilog
module manchester_encoder_axi4lite #(
    parameter ADDR_WIDTH = 4,
    parameter DATA_WIDTH = 32
)(
    input  wire                   clk,
    input  wire                   rst_n,
    // AXI4-Lite Write Address Channel
    input  wire [ADDR_WIDTH-1:0]  s_axi_awaddr,
    input  wire                   s_axi_awvalid,
    output reg                    s_axi_awready,
    // AXI4-Lite Write Data Channel
    input  wire [DATA_WIDTH-1:0]  s_axi_wdata,
    input  wire [(DATA_WIDTH/8)-1:0] s_axi_wstrb,
    input  wire                   s_axi_wvalid,
    output reg                    s_axi_wready,
    // AXI4-Lite Write Response Channel
    output reg  [1:0]             s_axi_bresp,
    output reg                    s_axi_bvalid,
    input  wire                   s_axi_bready,
    // AXI4-Lite Read Address Channel
    input  wire [ADDR_WIDTH-1:0]  s_axi_araddr,
    input  wire                   s_axi_arvalid,
    output reg                    s_axi_arready,
    // AXI4-Lite Read Data Channel
    output reg [DATA_WIDTH-1:0]   s_axi_rdata,
    output reg [1:0]              s_axi_rresp,
    output reg                    s_axi_rvalid,
    input  wire                   s_axi_rready,
    // manchester output
    output reg                    manchester_out
);

    // Internal registers mapped to AXI4-Lite address space
    reg                           enable_reg;
    reg                           data_in_reg;
    reg                           half_bit;

    // AXI4-Lite address map
    localparam ADDR_ENABLE    = 4'h0;
    localparam ADDR_DATA_IN   = 4'h4;
    localparam ADDR_MANCHESTER_OUT = 4'h8;

    // Write FSM
    reg aw_en;
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            s_axi_awready    <= 1'b0;
            s_axi_wready     <= 1'b0;
            s_axi_bvalid     <= 1'b0;
            s_axi_bresp      <= 2'b00;
            aw_en            <= 1'b1;
        end else begin
            // Write address handshake
            if (!s_axi_awready && s_axi_awvalid && aw_en) begin
                s_axi_awready <= 1'b1;
            end else begin
                s_axi_awready <= 1'b0;
            end

            // Write data handshake
            if (!s_axi_wready && s_axi_wvalid && aw_en) begin
                s_axi_wready <= 1'b1;
            end else begin
                s_axi_wready <= 1'b0;
            end

            // Write response
            if (s_axi_awready && s_axi_awvalid && s_axi_wready && s_axi_wvalid && aw_en) begin
                aw_en         <= 1'b0;
                s_axi_bvalid  <= 1'b1;
                s_axi_bresp   <= 2'b00;
                // Write operation
                case (s_axi_awaddr[ADDR_WIDTH-1:0])
                    ADDR_ENABLE: if (s_axi_wstrb[0]) enable_reg <= s_axi_wdata[0];
                    ADDR_DATA_IN: if (s_axi_wstrb[0]) data_in_reg <= s_axi_wdata[0];
                endcase
            end else if (s_axi_bvalid && s_axi_bready) begin
                s_axi_bvalid  <= 1'b0;
                aw_en         <= 1'b1;
            end
        end
    end

    // Read FSM Pipelined Path Cut
    reg [ADDR_WIDTH-1:0]     araddr_stage1;
    reg                      araddr_latch;
    reg [DATA_WIDTH-1:0]     rdata_stage1;
    reg [1:0]                rresp_stage1;
    reg                      rvalid_stage1;

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            s_axi_arready   <= 1'b0;
            araddr_stage1   <= {ADDR_WIDTH{1'b0}};
            araddr_latch    <= 1'b0;
        end else begin
            if (!s_axi_arready && s_axi_arvalid) begin
                s_axi_arready <= 1'b1;
                araddr_stage1 <= s_axi_araddr;
                araddr_latch  <= 1'b1;
            end else begin
                s_axi_arready <= 1'b0;
                if (araddr_latch)
                    araddr_latch <= 1'b0;
            end
        end
    end

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            rdata_stage1  <= {DATA_WIDTH{1'b0}};
            rresp_stage1  <= 2'b00;
            rvalid_stage1 <= 1'b0;
        end else begin
            if (araddr_latch) begin
                case (araddr_stage1)
                    ADDR_ENABLE:         rdata_stage1 <= {{(DATA_WIDTH-1){1'b0}}, enable_reg};
                    ADDR_DATA_IN:        rdata_stage1 <= {{(DATA_WIDTH-1){1'b0}}, data_in_reg};
                    ADDR_MANCHESTER_OUT: rdata_stage1 <= {{(DATA_WIDTH-1){1'b0}}, manchester_out};
                    default:             rdata_stage1 <= {DATA_WIDTH{1'b0}};
                endcase
                rresp_stage1  <= 2'b00;
                rvalid_stage1 <= 1'b1;
            end else if (rvalid_stage1 && s_axi_rready) begin
                rvalid_stage1 <= 1'b0;
            end
        end
    end

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            s_axi_rdata  <= {DATA_WIDTH{1'b0}};
            s_axi_rresp  <= 2'b00;
            s_axi_rvalid <= 1'b0;
        end else begin
            if (rvalid_stage1) begin
                s_axi_rdata  <= rdata_stage1;
                s_axi_rresp  <= rresp_stage1;
                s_axi_rvalid <= 1'b1;
            end else if (s_axi_rvalid && s_axi_rready) begin
                s_axi_rvalid <= 1'b0;
            end
        end
    end

    // Core Manchester Encoder Logic Pipelined
    reg half_bit_next;
    reg manchester_out_next;
    reg data_in_reg_q;
    reg enable_reg_q;

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            enable_reg_q <= 1'b0;
            data_in_reg_q <= 1'b0;
        end else begin
            enable_reg_q <= enable_reg;
            data_in_reg_q <= data_in_reg;
        end
    end

    always @(*) begin
        half_bit_next = half_bit;
        manchester_out_next = manchester_out;
        if (enable_reg_q) begin
            half_bit_next = ~half_bit;
            if (!half_bit)
                manchester_out_next = data_in_reg_q ? 1'b0 : 1'b1;
            else
                manchester_out_next = data_in_reg_q ? 1'b1 : 1'b0;
        end
    end

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            half_bit <= 1'b0;
            manchester_out <= 1'b0;
        end else begin
            half_bit <= half_bit_next;
            manchester_out <= manchester_out_next;
        end
    end

endmodule
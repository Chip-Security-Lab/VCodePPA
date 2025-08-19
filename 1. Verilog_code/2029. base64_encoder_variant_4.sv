//SystemVerilog
// Top-level Base64 Encoder Module with AXI4-Lite Interface
module base64_encoder_axi4lite #(
    parameter ADDR_WIDTH = 4 // Enough for 4 registers (0x0, 0x4, 0x8, 0xC)
)(
    input                  clk,
    input                  rst_n,

    // AXI4-Lite Write Address Channel
    input  [ADDR_WIDTH-1:0] s_axi_awaddr,
    input                   s_axi_awvalid,
    output reg              s_axi_awready,

    // AXI4-Lite Write Data Channel
    input  [31:0]           s_axi_wdata,
    input  [3:0]            s_axi_wstrb,
    input                   s_axi_wvalid,
    output reg              s_axi_wready,

    // AXI4-Lite Write Response Channel
    output reg [1:0]        s_axi_bresp,
    output reg              s_axi_bvalid,
    input                   s_axi_bready,

    // AXI4-Lite Read Address Channel
    input  [ADDR_WIDTH-1:0] s_axi_araddr,
    input                   s_axi_arvalid,
    output reg              s_axi_arready,

    // AXI4-Lite Read Data Channel
    output reg [31:0]       s_axi_rdata,
    output reg [1:0]        s_axi_rresp,
    output reg              s_axi_rvalid,
    input                   s_axi_rready
);

    // Internal Registers
    reg  [23:0] data_in_reg;
    wire [31:0] encoded_out_wire;

    // AXI4-Lite address decode
    localparam ADDR_DATA_IN    = 4'h0; // Write: 24-bit data input (lower 24 bits)
    localparam ADDR_ENCODED_OUT= 4'h4; // Read: 32-bit encoded output

    // AXI4-Lite write FSM
    reg aw_en;
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            s_axi_awready <= 1'b0;
            s_axi_wready  <= 1'b0;
            aw_en         <= 1'b1;
        end else begin
            if (!s_axi_awready && s_axi_awvalid && !s_axi_wready && s_axi_wvalid && aw_en) begin
                s_axi_awready <= 1'b1;
                s_axi_wready  <= 1'b1;
                aw_en <= 1'b0;
            end else if ((s_axi_bvalid && s_axi_bready) || !s_axi_awvalid || !s_axi_wvalid) begin
                s_axi_awready <= 1'b0;
                s_axi_wready  <= 1'b0;
                aw_en <= 1'b1;
            end
        end
    end

    // Write address and data latch
    reg [ADDR_WIDTH-1:0] axi_awaddr_latched;
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            axi_awaddr_latched <= {ADDR_WIDTH{1'b0}};
        end else if (s_axi_awready && s_axi_awvalid) begin
            axi_awaddr_latched <= s_axi_awaddr;
        end
    end

    // Write logic
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            data_in_reg <= 24'b0;
        end else if (s_axi_awready && s_axi_awvalid && s_axi_wready && s_axi_wvalid) begin
            case (s_axi_awaddr[ADDR_WIDTH-1:2])
                ADDR_DATA_IN[ADDR_WIDTH-1:2]: begin
                    // Only lower 24 bits are valid
                    if (s_axi_wstrb[2]) data_in_reg[23:16] <= s_axi_wdata[23:16];
                    if (s_axi_wstrb[1]) data_in_reg[15:8]  <= s_axi_wdata[15:8];
                    if (s_axi_wstrb[0]) data_in_reg[7:0]   <= s_axi_wdata[7:0];
                end
                default: ;
            endcase
        end
    end

    // Write response logic
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            s_axi_bvalid <= 1'b0;
            s_axi_bresp  <= 2'b00;
        end else begin
            if (s_axi_awready && s_axi_awvalid && s_axi_wready && s_axi_wvalid && !s_axi_bvalid) begin
                s_axi_bvalid <= 1'b1;
                s_axi_bresp  <= 2'b00; // OKAY
            end else if (s_axi_bvalid && s_axi_bready) begin
                s_axi_bvalid <= 1'b0;
            end
        end
    end

    // AXI4-Lite read FSM
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            s_axi_arready <= 1'b0;
            s_axi_rvalid  <= 1'b0;
            s_axi_rdata   <= 32'b0;
            s_axi_rresp   <= 2'b00;
        end else begin
            if (!s_axi_arready && s_axi_arvalid) begin
                s_axi_arready <= 1'b1;
            end else begin
                s_axi_arready <= 1'b0;
            end

            if (s_axi_arready && s_axi_arvalid && !s_axi_rvalid) begin
                case (s_axi_araddr[ADDR_WIDTH-1:2])
                    ADDR_DATA_IN[ADDR_WIDTH-1:2]: begin
                        s_axi_rdata <= {8'b0, data_in_reg};
                        s_axi_rresp <= 2'b00;
                    end
                    ADDR_ENCODED_OUT[ADDR_WIDTH-1:2]: begin
                        s_axi_rdata <= encoded_out_wire;
                        s_axi_rresp <= 2'b00;
                    end
                    default: begin
                        s_axi_rdata <= 32'b0;
                        s_axi_rresp <= 2'b10; // SLVERR
                    end
                endcase
                s_axi_rvalid <= 1'b1;
            end else if (s_axi_rvalid && s_axi_rready) begin
                s_axi_rvalid <= 1'b0;
            end
        end
    end

    // Core logic instantiation
    base64_encoder_core u_base64_encoder_core (
        .data_in    (data_in_reg),
        .encoded_out(encoded_out_wire)
    );

endmodule

// ---------------------------------------------------------------------------
// Base64 Encoder Core (original core logic, interface unchanged)
// ---------------------------------------------------------------------------
module base64_encoder_core (
    input  [23:0] data_in,
    output [31:0] encoded_out
);

    wire [5:0] seg0;
    wire [5:0] seg1;
    wire [5:0] seg2;
    wire [5:0] seg3;

    wire [7:0] char0;
    wire [7:0] char1;
    wire [7:0] char2;
    wire [7:0] char3;

    // Segment Extractor: Splits 24-bit input into four 6-bit segments
    base64_segment_extractor u_segment_extractor (
        .data_in (data_in),
        .seg0    (seg0),
        .seg1    (seg1),
        .seg2    (seg2),
        .seg3    (seg3)
    );

    // Character Mapper: Maps 6-bit segments to 8-bit ASCII/Base64 characters
    base64_char_mapper u_char_mapper0 (
        .seg_in  (seg0),
        .char_out(char0)
    );

    base64_char_mapper u_char_mapper1 (
        .seg_in  (seg1),
        .char_out(char1)
    );

    base64_char_mapper u_char_mapper2 (
        .seg_in  (seg2),
        .char_out(char2)
    );

    base64_char_mapper u_char_mapper3 (
        .seg_in  (seg3),
        .char_out(char3)
    );

    assign encoded_out = {char0, char1, char2, char3};

endmodule

// ---------------------------------------------------------------------------
// Segment Extractor Submodule
// Splits 24-bit data into four 6-bit segments for Base64 encoding
// ---------------------------------------------------------------------------
module base64_segment_extractor (
    input  [23:0] data_in,
    output [5:0]  seg0,
    output [5:0]  seg1,
    output [5:0]  seg2,
    output [5:0]  seg3
);
    assign seg0 = data_in[23:18];
    assign seg1 = data_in[17:12];
    assign seg2 = data_in[11:6];
    assign seg3 = data_in[5:0];
endmodule

// ---------------------------------------------------------------------------
// Character Mapper Submodule
// Maps a 6-bit segment to corresponding 8-bit Base64 character
// (For demonstration, mapping is identity; replace with actual mapping as needed.)
// ---------------------------------------------------------------------------
module base64_char_mapper (
    input  [5:0] seg_in,
    output reg [7:0] char_out
);
    always @* begin
        // Simplified mapping: direct assignment (replace with character set mapping for full compliance)
        char_out = {2'b00, seg_in};
    end
endmodule
//SystemVerilog
module priority_shifter_axi4lite #(
    parameter ADDR_WIDTH = 4,    // Enough for 2 registers (4 bytes aligned)
    parameter DATA_WIDTH = 32    // AXI4-Lite standard data width
)(
    input                     axi_aclk,
    input                     axi_aresetn,

    // AXI4-Lite Write Address Channel
    input      [ADDR_WIDTH-1:0] s_axi_awaddr,
    input                       s_axi_awvalid,
    output reg                  s_axi_awready,

    // AXI4-Lite Write Data Channel
    input      [DATA_WIDTH-1:0] s_axi_wdata,
    input      [DATA_WIDTH/8-1:0] s_axi_wstrb,
    input                       s_axi_wvalid,
    output reg                  s_axi_wready,

    // AXI4-Lite Write Response Channel
    output reg [1:0]            s_axi_bresp,
    output reg                  s_axi_bvalid,
    input                       s_axi_bready,

    // AXI4-Lite Read Address Channel
    input      [ADDR_WIDTH-1:0] s_axi_araddr,
    input                       s_axi_arvalid,
    output reg                  s_axi_arready,

    // AXI4-Lite Read Data Channel
    output reg [DATA_WIDTH-1:0] s_axi_rdata,
    output reg [1:0]            s_axi_rresp,
    output reg                  s_axi_rvalid,
    input                       s_axi_rready
);

// Internal registers for memory-mapped interface
reg [15:0] in_data_reg;
reg [15:0] priority_mask_reg;
reg [15:0] out_data_reg;

// Write state machine
reg aw_en;

localparam
    ADDR_IN_DATA        = 4'h0,
    ADDR_PRIORITY_MASK  = 4'h4,
    ADDR_OUT_DATA       = 4'h8;

// AXI4-Lite write address handshake
always @(posedge axi_aclk) begin
    if (~axi_aresetn) begin
        s_axi_awready <= 1'b0;
        s_axi_wready  <= 1'b0;
        aw_en         <= 1'b1;
    end else begin
        if (~s_axi_awready && s_axi_awvalid && s_axi_wvalid && aw_en) begin
            s_axi_awready <= 1'b1;
            s_axi_wready  <= 1'b1;
            aw_en         <= 1'b0;
        end else if (s_axi_bvalid && s_axi_bready) begin
            s_axi_awready <= 1'b0;
            s_axi_wready  <= 1'b0;
            aw_en         <= 1'b1;
        end else begin
            s_axi_awready <= 1'b0;
            s_axi_wready  <= 1'b0;
        end
    end
end

// Write logic
always @(posedge axi_aclk) begin
    if (~axi_aresetn) begin
        in_data_reg        <= 16'd0;
        priority_mask_reg  <= 16'd0;
        s_axi_bvalid       <= 1'b0;
        s_axi_bresp        <= 2'b00;
    end else begin
        if (s_axi_awready && s_axi_awvalid && s_axi_wready && s_axi_wvalid) begin
            case (s_axi_awaddr[ADDR_WIDTH-1:2])
                2'b00: begin // 0x0: in_data_reg
                    if (s_axi_wstrb[1]) in_data_reg[15:8]  <= s_axi_wdata[15:8];
                    if (s_axi_wstrb[0]) in_data_reg[7:0]   <= s_axi_wdata[7:0];
                end
                2'b01: begin // 0x4: priority_mask_reg
                    if (s_axi_wstrb[1]) priority_mask_reg[15:8] <= s_axi_wdata[15:8];
                    if (s_axi_wstrb[0]) priority_mask_reg[7:0]  <= s_axi_wdata[7:0];
                end
                default: ;
            endcase
            s_axi_bvalid <= 1'b1;
            s_axi_bresp  <= 2'b00; // OKAY
        end else if (s_axi_bvalid && s_axi_bready) begin
            s_axi_bvalid <= 1'b0;
        end
    end
end

// AXI4-Lite read address handshake
always @(posedge axi_aclk) begin
    if (~axi_aresetn) begin
        s_axi_arready <= 1'b0;
    end else begin
        if (~s_axi_arready && s_axi_arvalid) begin
            s_axi_arready <= 1'b1;
        end else begin
            s_axi_arready <= 1'b0;
        end
    end
end

// AXI4-Lite read data channel
always @(posedge axi_aclk) begin
    if (~axi_aresetn) begin
        s_axi_rvalid <= 1'b0;
        s_axi_rresp  <= 2'b00;
        s_axi_rdata  <= {DATA_WIDTH{1'b0}};
    end else begin
        if (s_axi_arready && s_axi_arvalid) begin
            case (s_axi_araddr[ADDR_WIDTH-1:2])
                2'b00: s_axi_rdata <= {16'd0, in_data_reg};
                2'b01: s_axi_rdata <= {16'd0, priority_mask_reg};
                2'b10: s_axi_rdata <= {16'd0, out_data_reg};
                default: s_axi_rdata <= {DATA_WIDTH{1'b0}};
            endcase
            s_axi_rvalid <= 1'b1;
            s_axi_rresp  <= 2'b00; // OKAY
        end else if (s_axi_rvalid && s_axi_rready) begin
            s_axi_rvalid <= 1'b0;
        end
    end
end

// Priority encoder and shifter logic
wire [3:0] highest_priority;
assign highest_priority = priority_mask_reg[15] ? 4'd15 :
                         priority_mask_reg[14] ? 4'd14 :
                         priority_mask_reg[13] ? 4'd13 :
                         priority_mask_reg[12] ? 4'd12 :
                         priority_mask_reg[11] ? 4'd11 :
                         priority_mask_reg[10] ? 4'd10 :
                         priority_mask_reg[9]  ? 4'd9  :
                         priority_mask_reg[8]  ? 4'd8  :
                         priority_mask_reg[7]  ? 4'd7  :
                         priority_mask_reg[6]  ? 4'd6  :
                         priority_mask_reg[5]  ? 4'd5  :
                         priority_mask_reg[4]  ? 4'd4  :
                         priority_mask_reg[3]  ? 4'd3  :
                         priority_mask_reg[2]  ? 4'd2  :
                         priority_mask_reg[1]  ? 4'd1  :
                         priority_mask_reg[0]  ? 4'd0  : 4'd0;

always @(posedge axi_aclk) begin
    if (~axi_aresetn) begin
        out_data_reg <= 16'd0;
    end else begin
        case (highest_priority)
            4'd0:  out_data_reg <= in_data_reg << 0;
            4'd1:  out_data_reg <= in_data_reg << 1;
            4'd2:  out_data_reg <= in_data_reg << 2;
            4'd3:  out_data_reg <= in_data_reg << 3;
            4'd4:  out_data_reg <= in_data_reg << 4;
            4'd5:  out_data_reg <= in_data_reg << 5;
            4'd6:  out_data_reg <= in_data_reg << 6;
            4'd7:  out_data_reg <= in_data_reg << 7;
            4'd8:  out_data_reg <= in_data_reg << 8;
            4'd9:  out_data_reg <= in_data_reg << 9;
            4'd10: out_data_reg <= in_data_reg << 10;
            4'd11: out_data_reg <= in_data_reg << 11;
            4'd12: out_data_reg <= in_data_reg << 12;
            4'd13: out_data_reg <= in_data_reg << 13;
            4'd14: out_data_reg <= in_data_reg << 14;
            4'd15: out_data_reg <= in_data_reg << 15;
            default: out_data_reg <= in_data_reg;
        endcase
    end
end

endmodule
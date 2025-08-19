//SystemVerilog
module nibble_rotation_shifter_axi4lite #(
    parameter ADDR_WIDTH = 4
)(
    input                   clk,
    input                   resetn,
    // AXI4-Lite Write Address Channel
    input  [ADDR_WIDTH-1:0] s_axi_awaddr,
    input                   s_axi_awvalid,
    output                  s_axi_awready,
    // AXI4-Lite Write Data Channel
    input  [15:0]           s_axi_wdata,
    input  [1:0]            s_axi_wstrb,
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
    output [15:0]           s_axi_rdata,
    output [1:0]            s_axi_rresp,
    output                  s_axi_rvalid,
    input                   s_axi_rready
);

    // AXI4-Lite Address Map
    localparam ADDR_DATA            = 4'h0; // 0x0
    localparam ADDR_NIBBLE_SEL      = 4'h4; // 0x4
    localparam ADDR_SPECIFIC_NIBBLE = 4'h8; // 0x8
    localparam ADDR_ROTATE_AMOUNT   = 4'hC; // 0xC
    localparam ADDR_RESULT          = 4'h10; // 0x10

    // Internal registers for memory-mapped inputs
    reg  [15:0] reg_data;
    reg  [1:0]  reg_nibble_sel;
    reg  [1:0]  reg_specific_nibble;
    reg  [1:0]  reg_rotate_amount;

    // AXI4-Lite handshake signals
    reg         awready_reg, wready_reg, bvalid_reg, arready_reg, rvalid_reg;
    reg  [1:0]  bresp_reg, rresp_reg;
    reg  [15:0] rdata_reg;

    // Write address and data latching
    reg         aw_en;
    reg  [ADDR_WIDTH-1:0] awaddr_reg;

    // Write address handshake
    always @(posedge clk) begin
        if (!resetn) begin
            awready_reg <= 1'b0;
            aw_en <= 1'b1;
        end else begin
            if (~awready_reg && s_axi_awvalid && s_axi_wvalid && aw_en) begin
                awready_reg <= 1'b1;
                awaddr_reg <= s_axi_awaddr;
                aw_en <= 1'b0;
            end else if (s_axi_bready && bvalid_reg) begin
                awready_reg <= 1'b0;
                aw_en <= 1'b1;
            end else begin
                awready_reg <= 1'b0;
            end
        end
    end
    assign s_axi_awready = awready_reg;

    // Write data handshake
    always @(posedge clk) begin
        if (!resetn) begin
            wready_reg <= 1'b0;
        end else begin
            if (~wready_reg && s_axi_wvalid && s_axi_awvalid && aw_en) begin
                wready_reg <= 1'b1;
            end else begin
                wready_reg <= 1'b0;
            end
        end
    end
    assign s_axi_wready = wready_reg;

    // Write operation
    always @(posedge clk) begin
        if (!resetn) begin
            reg_data            <= 16'd0;
            reg_nibble_sel      <= 2'd0;
            reg_specific_nibble <= 2'd0;
            reg_rotate_amount   <= 2'd0;
        end else if (awready_reg && s_axi_awvalid && wready_reg && s_axi_wvalid) begin
            case (awaddr_reg)
                ADDR_DATA: begin
                    if (s_axi_wstrb[1]) reg_data[15:8] <= s_axi_wdata[15:8];
                    if (s_axi_wstrb[0]) reg_data[7:0]  <= s_axi_wdata[7:0];
                end
                ADDR_NIBBLE_SEL: begin
                    if (s_axi_wstrb[0]) reg_nibble_sel <= s_axi_wdata[1:0];
                end
                ADDR_SPECIFIC_NIBBLE: begin
                    if (s_axi_wstrb[0]) reg_specific_nibble <= s_axi_wdata[1:0];
                end
                ADDR_ROTATE_AMOUNT: begin
                    if (s_axi_wstrb[0]) reg_rotate_amount <= s_axi_wdata[1:0];
                end
                default: ;
            endcase
        end
    end

    // Write response logic
    always @(posedge clk) begin
        if (!resetn) begin
            bvalid_reg <= 1'b0;
            bresp_reg  <= 2'b00;
        end else begin
            if (awready_reg && s_axi_awvalid && wready_reg && s_axi_wvalid && ~bvalid_reg) begin
                bvalid_reg <= 1'b1;
                bresp_reg  <= 2'b00; // OKAY
            end else if (s_axi_bready && bvalid_reg) begin
                bvalid_reg <= 1'b0;
            end
        end
    end
    assign s_axi_bvalid = bvalid_reg;
    assign s_axi_bresp  = bresp_reg;

    // Read address handshake
    always @(posedge clk) begin
        if (!resetn) begin
            arready_reg <= 1'b0;
        end else begin
            if (~arready_reg && s_axi_arvalid) begin
                arready_reg <= 1'b1;
            end else begin
                arready_reg <= 1'b0;
            end
        end
    end
    assign s_axi_arready = arready_reg;

    // Read operation
    always @(posedge clk) begin
        if (!resetn) begin
            rvalid_reg <= 1'b0;
            rresp_reg  <= 2'b00;
            rdata_reg  <= 16'd0;
        end else begin
            if (~rvalid_reg && s_axi_arvalid && arready_reg) begin
                case (s_axi_araddr)
                    ADDR_DATA:            rdata_reg <= reg_data;
                    ADDR_NIBBLE_SEL:      rdata_reg <= {14'd0, reg_nibble_sel};
                    ADDR_SPECIFIC_NIBBLE: rdata_reg <= {14'd0, reg_specific_nibble};
                    ADDR_ROTATE_AMOUNT:   rdata_reg <= {14'd0, reg_rotate_amount};
                    ADDR_RESULT:          rdata_reg <= result_reg;
                    default:              rdata_reg <= 16'd0;
                endcase
                rvalid_reg <= 1'b1;
                rresp_reg  <= 2'b00; // OKAY
            end else if (rvalid_reg && s_axi_rready) begin
                rvalid_reg <= 1'b0;
            end
        end
    end
    assign s_axi_rvalid = rvalid_reg;
    assign s_axi_rresp  = rresp_reg;
    assign s_axi_rdata  = rdata_reg;

    // Core logic
    wire [3:0] nibble0 = reg_data[3:0];
    wire [3:0] nibble1 = reg_data[7:4];
    wire [3:0] nibble2 = reg_data[11:8];
    wire [3:0] nibble3 = reg_data[15:12];

    // Optimized rotate logic using casez for better PPA and clarity
    reg [3:0] rotated_nibble0, rotated_nibble1, rotated_nibble2, rotated_nibble3;
    always @(*) begin
        case (reg_rotate_amount)
            2'b00: begin
                rotated_nibble0 = nibble0;
                rotated_nibble1 = nibble1;
                rotated_nibble2 = nibble2;
                rotated_nibble3 = nibble3;
            end
            2'b01: begin
                rotated_nibble0 = {nibble0[2:0], nibble0[3]};
                rotated_nibble1 = {nibble1[2:0], nibble1[3]};
                rotated_nibble2 = {nibble2[2:0], nibble2[3]};
                rotated_nibble3 = {nibble3[2:0], nibble3[3]};
            end
            2'b10: begin
                rotated_nibble0 = {nibble0[1:0], nibble0[3:2]};
                rotated_nibble1 = {nibble1[1:0], nibble1[3:2]};
                rotated_nibble2 = {nibble2[1:0], nibble2[3:2]};
                rotated_nibble3 = {nibble3[1:0], nibble3[3:2]};
            end
            default: begin
                rotated_nibble0 = {nibble0[0], nibble0[3:1]};
                rotated_nibble1 = {nibble1[0], nibble1[3:1]};
                rotated_nibble2 = {nibble2[0], nibble2[3:1]};
                rotated_nibble3 = {nibble3[0], nibble3[3:1]};
            end
        endcase
    end

    // Optimized result selection logic
    reg [15:0] result_reg;
    always @(*) begin
        reg [15:0] temp_result;
        case (reg_nibble_sel)
            2'b00: temp_result = {rotated_nibble3, rotated_nibble2, rotated_nibble1, rotated_nibble0};
            2'b01: temp_result = {rotated_nibble3, rotated_nibble2, nibble1, nibble0};
            2'b10: temp_result = {nibble3, nibble2, rotated_nibble1, rotated_nibble0};
            default: begin
                // 2'b11: use reg_specific_nibble
                case (reg_specific_nibble)
                    2'b00: temp_result = {nibble3, nibble2, nibble1, rotated_nibble0};
                    2'b01: temp_result = {nibble3, nibble2, rotated_nibble1, nibble0};
                    2'b10: temp_result = {nibble3, rotated_nibble2, nibble1, nibble0};
                    2'b11: temp_result = {rotated_nibble3, nibble2, nibble1, nibble0};
                    default: temp_result = reg_data;
                endcase
            end
        endcase
        result_reg = temp_result;
    end

endmodule
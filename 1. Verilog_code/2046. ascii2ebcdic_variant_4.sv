//SystemVerilog
module ascii2ebcdic_axi4lite (
    input wire         ACLK,
    input wire         ARESETN,
    // AXI4-Lite Write Address Channel
    input wire  [3:0]  AWADDR,
    input wire         AWVALID,
    output reg         AWREADY,
    // AXI4-Lite Write Data Channel
    input wire  [7:0]  WDATA,
    input wire  [0:0]  WSTRB,
    input wire         WVALID,
    output reg         WREADY,
    // AXI4-Lite Write Response Channel
    output reg  [1:0]  BRESP,
    output reg         BVALID,
    input wire         BREADY,
    // AXI4-Lite Read Address Channel
    input wire  [3:0]  ARADDR,
    input wire         ARVALID,
    output reg         ARREADY,
    // AXI4-Lite Read Data Channel
    output reg [7:0]   RDATA,
    output reg [1:0]   RRESP,
    output reg         RVALID,
    input wire         RREADY
);

    // Internal registers for memory-mapped registers
    reg [7:0] ascii_reg;
    reg       ascii_reg_we;
    reg [7:0] ebcdic_reg;
    reg       valid_reg;

    // Write FSM
    reg aw_hs, w_hs;
    wire write_en;
    reg [3:0] awaddr_reg;

    assign write_en = aw_hs & w_hs;

    // Read FSM
    reg ar_hs;
    reg [3:0] araddr_reg;

    // Write address handshake
    always @(posedge ACLK or negedge ARESETN) begin
        if (!ARESETN) begin
            AWREADY <= 1'b0;
            aw_hs <= 1'b0;
        end else begin
            if (!AWREADY && AWVALID) begin
                AWREADY <= 1'b1;
                awaddr_reg <= AWADDR;
                aw_hs <= 1'b1;
            end else begin
                AWREADY <= 1'b0;
                aw_hs <= 1'b0;
            end
        end
    end

    // Write data handshake
    always @(posedge ACLK or negedge ARESETN) begin
        if (!ARESETN) begin
            WREADY <= 1'b0;
            w_hs <= 1'b0;
        end else begin
            if (!WREADY && WVALID) begin
                WREADY <= 1'b1;
                w_hs <= 1'b1;
            end else begin
                WREADY <= 1'b0;
                w_hs <= 1'b0;
            end
        end
    end

    // Write operation
    always @(posedge ACLK or negedge ARESETN) begin
        if (!ARESETN) begin
            ascii_reg <= 8'h00;
            ascii_reg_we <= 1'b0;
        end else begin
            ascii_reg_we <= 1'b0;
            if (write_en) begin
                if (awaddr_reg == 4'h0) begin
                    if (WSTRB[0]) begin
                        ascii_reg <= WDATA;
                        ascii_reg_we <= 1'b1;
                    end
                end
            end
        end
    end

    // Write response logic
    always @(posedge ACLK or negedge ARESETN) begin
        if (!ARESETN) begin
            BVALID <= 1'b0;
            BRESP <= 2'b00;
        end else begin
            if (write_en) begin
                BVALID <= 1'b1;
                BRESP <= 2'b00;
            end else if (BVALID && BREADY) begin
                BVALID <= 1'b0;
            end
        end
    end

    // Read address handshake
    always @(posedge ACLK or negedge ARESETN) begin
        if (!ARESETN) begin
            ARREADY <= 1'b0;
            ar_hs <= 1'b0;
        end else begin
            if (!ARREADY && ARVALID) begin
                ARREADY <= 1'b1;
                araddr_reg <= ARADDR;
                ar_hs <= 1'b1;
            end else begin
                ARREADY <= 1'b0;
                ar_hs <= 1'b0;
            end
        end
    end

    // Read operation and response logic
    always @(posedge ACLK or negedge ARESETN) begin
        if (!ARESETN) begin
            RVALID <= 1'b0;
            RDATA <= 8'h00;
            RRESP <= 2'b00;
        end else begin
            if (ar_hs) begin
                case (araddr_reg)
                    4'h4: RDATA <= ebcdic_reg;
                    4'h8: RDATA <= {7'b0, valid_reg};
                    default: RDATA <= 8'h00;
                endcase
                RVALID <= 1'b1;
                RRESP <= 2'b00;
            end else if (RVALID && RREADY) begin
                RVALID <= 1'b0;
            end
        end
    end

    // ASCII to EBCDIC logic
    reg [7:0] ebcdic_next;
    reg       valid_next;
    always @* begin
        case (ascii_reg)
            8'h30: begin
                ebcdic_next = 8'hF0;
                valid_next  = 1'b1;
            end
            8'h31: begin
                ebcdic_next = 8'hF1;
                valid_next  = 1'b1;
            end
            8'h41: begin
                ebcdic_next = 8'hC1;
                valid_next  = 1'b1;
            end
            8'h42: begin
                ebcdic_next = 8'hC2;
                valid_next  = 1'b1;
            end
            default: begin
                ebcdic_next = 8'h00;
                valid_next  = 1'b0;
            end
        endcase
    end

    always @(posedge ACLK or negedge ARESETN) begin
        if (!ARESETN) begin
            ebcdic_reg <= 8'h00;
            valid_reg  <= 1'b0;
        end else begin
            if (ascii_reg_we) begin
                ebcdic_reg <= ebcdic_next;
                valid_reg  <= valid_next;
            end else begin
                valid_reg <= 1'b0;
            end
        end
    end

endmodule
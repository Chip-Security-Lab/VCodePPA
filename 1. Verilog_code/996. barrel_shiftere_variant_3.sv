//SystemVerilog
module barrel_shifter_axi4lite #(
    parameter ADDR_WIDTH = 4,      // 16-bit address space
    parameter DATA_WIDTH = 16      // Data width
)(
    // AXI4-Lite Write Address Channel
    input                   ACLK,
    input                   ARESETN,
    input  [ADDR_WIDTH-1:0] S_AXI_AWADDR,
    input                   S_AXI_AWVALID,
    output                  S_AXI_AWREADY,
    // AXI4-Lite Write Data Channel
    input  [DATA_WIDTH-1:0] S_AXI_WDATA,
    input  [(DATA_WIDTH/8)-1:0] S_AXI_WSTRB,
    input                   S_AXI_WVALID,
    output                  S_AXI_WREADY,
    // AXI4-Lite Write Response Channel
    output [1:0]            S_AXI_BRESP,
    output                  S_AXI_BVALID,
    input                   S_AXI_BREADY,
    // AXI4-Lite Read Address Channel
    input  [ADDR_WIDTH-1:0] S_AXI_ARADDR,
    input                   S_AXI_ARVALID,
    output                  S_AXI_ARREADY,
    // AXI4-Lite Read Data Channel
    output [DATA_WIDTH-1:0] S_AXI_RDATA,
    output [1:0]            S_AXI_RRESP,
    output                  S_AXI_RVALID,
    input                   S_AXI_RREADY
);

    // Internal registers for mapped signals
    reg [DATA_WIDTH-1:0] din_reg;
    reg [3:0]            shamt_reg;
    reg                  dir_reg;
    reg [DATA_WIDTH-1:0] dout_reg;

    // AXI4-Lite handshake signals
    reg                  awready_reg;
    reg                  wready_reg;
    reg                  bvalid_reg;
    reg [1:0]            bresp_reg;
    reg                  arready_reg;
    reg [DATA_WIDTH-1:0] rdata_reg;
    reg [1:0]            rresp_reg;
    reg                  rvalid_reg;

    // Write address and data latching
    reg [ADDR_WIDTH-1:0] awaddr_latch;
    reg                  awvalid_latch;
    reg                  wvalid_latch;
    reg [ADDR_WIDTH-1:0] araddr_latch;

    // AXI4-Lite output assignments
    assign S_AXI_AWREADY = awready_reg;
    assign S_AXI_WREADY  = wready_reg;
    assign S_AXI_BRESP   = bresp_reg;
    assign S_AXI_BVALID  = bvalid_reg;
    assign S_AXI_ARREADY = arready_reg;
    assign S_AXI_RDATA   = rdata_reg;
    assign S_AXI_RRESP   = rresp_reg;
    assign S_AXI_RVALID  = rvalid_reg;

    // Address map
    localparam ADDR_DIN    = 4'h0;
    localparam ADDR_SHAMT  = 4'h4;
    localparam ADDR_DIR    = 4'h8;
    localparam ADDR_DOUT   = 4'hC;

    // Write address handshake
    always @(posedge ACLK or negedge ARESETN) begin
        if (!ARESETN) begin
            awready_reg <= 1'b0;
            awaddr_latch <= {ADDR_WIDTH{1'b0}};
            awvalid_latch <= 1'b0;
        end else begin
            if (!awready_reg && S_AXI_AWVALID) begin
                awready_reg <= 1'b1;
                awaddr_latch <= S_AXI_AWADDR;
                awvalid_latch <= 1'b1;
            end else if (S_AXI_WVALID && wready_reg) begin
                awready_reg <= 1'b0;
                awvalid_latch <= 1'b0;
            end
        end
    end

    // Write data handshake
    always @(posedge ACLK or negedge ARESETN) begin
        if (!ARESETN) begin
            wready_reg <= 1'b0;
            wvalid_latch <= 1'b0;
        end else begin
            if (!wready_reg && S_AXI_WVALID) begin
                wready_reg <= 1'b1;
                wvalid_latch <= 1'b1;
            end else if (S_AXI_WVALID && wready_reg) begin
                wready_reg <= 1'b0;
                wvalid_latch <= 1'b0;
            end
        end
    end

    // Write operation
    always @(posedge ACLK or negedge ARESETN) begin
        if (!ARESETN) begin
            din_reg   <= {DATA_WIDTH{1'b0}};
            shamt_reg <= 4'b0;
            dir_reg   <= 1'b0;
        end else if (awready_reg && wready_reg && S_AXI_AWVALID && S_AXI_WVALID) begin
            if (awaddr_latch == ADDR_DIN) begin
                if (S_AXI_WSTRB[1]) din_reg[15:8] <= S_AXI_WDATA[15:8];
                if (S_AXI_WSTRB[0]) din_reg[7:0]  <= S_AXI_WDATA[7:0];
            end else if (awaddr_latch == ADDR_SHAMT) begin
                shamt_reg <= S_AXI_WDATA[3:0];
            end else if (awaddr_latch == ADDR_DIR) begin
                dir_reg <= S_AXI_WDATA[0];
            end
        end
    end

    // Write response channel
    always @(posedge ACLK or negedge ARESETN) begin
        if (!ARESETN) begin
            bvalid_reg <= 1'b0;
            bresp_reg  <= 2'b00;
        end else begin
            if (awready_reg && wready_reg && S_AXI_AWVALID && S_AXI_WVALID && !bvalid_reg) begin
                bvalid_reg <= 1'b1;
                bresp_reg  <= 2'b00; // OKAY
            end else if (bvalid_reg && S_AXI_BREADY) begin
                bvalid_reg <= 1'b0;
            end
        end
    end

    // Read address handshake
    always @(posedge ACLK or negedge ARESETN) begin
        if (!ARESETN) begin
            arready_reg <= 1'b0;
            araddr_latch <= {ADDR_WIDTH{1'b0}};
        end else begin
            if (!arready_reg && S_AXI_ARVALID) begin
                arready_reg <= 1'b1;
                araddr_latch <= S_AXI_ARADDR;
            end else if (S_AXI_ARVALID && arready_reg) begin
                arready_reg <= 1'b0;
            end
        end
    end

    // Read data channel
    always @(posedge ACLK or negedge ARESETN) begin
        if (!ARESETN) begin
            rvalid_reg <= 1'b0;
            rresp_reg  <= 2'b00;
            rdata_reg  <= {DATA_WIDTH{1'b0}};
        end else begin
            if (arready_reg && S_AXI_ARVALID && !rvalid_reg) begin
                if (araddr_latch == ADDR_DIN) begin
                    rdata_reg <= din_reg;
                end else if (araddr_latch == ADDR_SHAMT) begin
                    rdata_reg <= {12'b0, shamt_reg};
                end else if (araddr_latch == ADDR_DIR) begin
                    rdata_reg <= {15'b0, dir_reg};
                end else if (araddr_latch == ADDR_DOUT) begin
                    rdata_reg <= dout_reg;
                end else begin
                    rdata_reg <= {DATA_WIDTH{1'b0}};
                end
                rvalid_reg <= 1'b1;
                rresp_reg  <= 2'b00; // OKAY
            end else if (rvalid_reg && S_AXI_RREADY) begin
                rvalid_reg <= 1'b0;
            end
        end
    end

    // Optimized Barrel shifter combinational logic
    reg [15:0] shift_result;

    always @(*) begin
        // Circular barrel shift
        case ({dir_reg, shamt_reg})
            // dir_reg == 1'b1 : left (rotate left)
            // dir_reg == 1'b0 : right (rotate right)
            // Efficiently use one operation with modulus
            default: begin
                if (shamt_reg == 4'd0) begin
                    shift_result = din_reg;
                end else if (dir_reg) begin // Left rotate
                    shift_result = (din_reg << shamt_reg) | (din_reg >> (16 - shamt_reg));
                end else begin // Right rotate
                    shift_result = (din_reg >> shamt_reg) | (din_reg << (16 - shamt_reg));
                end
            end
        endcase
    end

    // Latch output register on write or input change
    always @(posedge ACLK or negedge ARESETN) begin
        if (!ARESETN) begin
            dout_reg <= 16'b0;
        end else begin
            dout_reg <= shift_result;
        end
    end

endmodule
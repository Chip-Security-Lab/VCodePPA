//SystemVerilog
module log_pipeline_axi4lite #(
    parameter ADDR_WIDTH = 4, // 16 bytes address space for 4 registers
    parameter DATA_WIDTH = 16
)(
    input                   ACLK,
    input                   ARESETN,
    // AXI4-Lite Write Address Channel
    input  [ADDR_WIDTH-1:0] AWADDR,
    input                   AWVALID,
    output                  AWREADY,
    // AXI4-Lite Write Data Channel
    input  [DATA_WIDTH-1:0] WDATA,
    input  [(DATA_WIDTH/8)-1:0] WSTRB,
    input                   WVALID,
    output                  WREADY,
    // AXI4-Lite Write Response Channel
    output [1:0]            BRESP,
    output                  BVALID,
    input                   BREADY,
    // AXI4-Lite Read Address Channel
    input  [ADDR_WIDTH-1:0] ARADDR,
    input                   ARVALID,
    output                  ARREADY,
    // AXI4-Lite Read Data Channel
    output [DATA_WIDTH-1:0] RDATA,
    output [1:0]            RRESP,
    output                  RVALID,
    input                   RREADY
);

    // Internal Registers
    reg [DATA_WIDTH-1:0] pipe [0:3];    // Pipeline registers
    reg [DATA_WIDTH-1:0] in_reg;        // Input register
    reg                  en_reg;        // Enable register

    // AXI4-Lite handshake signals
    reg                  awready_reg;
    reg                  wready_reg;
    reg                  bvalid_reg;
    reg [1:0]            bresp_reg;
    reg                  arready_reg;
    reg                  rvalid_reg;
    reg [DATA_WIDTH-1:0] rdata_reg;
    reg [1:0]            rresp_reg;

    // Write state machine
    reg                  aw_en;
    reg [ADDR_WIDTH-1:0] awaddr_reg;

    // Reset and handshake assignments
    assign AWREADY = awready_reg;
    assign WREADY  = wready_reg;
    assign BRESP   = bresp_reg;
    assign BVALID  = bvalid_reg;
    assign ARREADY = arready_reg;
    assign RDATA   = rdata_reg;
    assign RRESP   = rresp_reg;
    assign RVALID  = rvalid_reg;

    // Write Address Channel
    always @(posedge ACLK) begin
        if (!ARESETN) begin
            awready_reg <= 1'b0;
            awaddr_reg  <= {ADDR_WIDTH{1'b0}};
            aw_en       <= 1'b1;
        end else begin
            if (!awready_reg && AWVALID && aw_en) begin
                awready_reg <= 1'b1;
                awaddr_reg  <= AWADDR;
                aw_en       <= 1'b0;
            end else if (BREADY && bvalid_reg) begin
                aw_en       <= 1'b1;
                awready_reg <= 1'b0;
            end else begin
                awready_reg <= 1'b0;
            end
        end
    end

    // Write Data Channel
    always @(posedge ACLK) begin
        if (!ARESETN) begin
            wready_reg <= 1'b0;
        end else begin
            if (!wready_reg && WVALID && awready_reg) begin
                wready_reg <= 1'b1;
            end else begin
                wready_reg <= 1'b0;
            end
        end
    end

    // Write Operation
    always @(posedge ACLK) begin
        if (!ARESETN) begin
            in_reg  <= {DATA_WIDTH{1'b0}};
            en_reg  <= 1'b0;
        end else begin
            if (awready_reg && WVALID && wready_reg) begin
                case (awaddr_reg[3:2]) // 4-word address space, word-aligned
                    2'b00: begin
                        if (WSTRB[1]) in_reg[15:8] <= WDATA[15:8];
                        if (WSTRB[0]) in_reg[7:0]  <= WDATA[7:0];
                    end
                    2'b01: begin
                        en_reg <= WDATA[0];
                    end
                    default: ;
                endcase
            end
        end
    end

    // Write Response Channel
    always @(posedge ACLK) begin
        if (!ARESETN) begin
            bvalid_reg <= 1'b0;
            bresp_reg  <= 2'b00;
        end else begin
            if (awready_reg && wready_reg && WVALID) begin
                bvalid_reg <= 1'b1;
                bresp_reg  <= 2'b00; // OKAY
            end else if (bvalid_reg && BREADY) begin
                bvalid_reg <= 1'b0;
            end
        end
    end

    // Read Address Channel
    always @(posedge ACLK) begin
        if (!ARESETN) begin
            arready_reg <= 1'b0;
        end else begin
            if (!arready_reg && ARVALID) begin
                arready_reg <= 1'b1;
            end else begin
                arready_reg <= 1'b0;
            end
        end
    end

    // Read Data Channel
    always @(posedge ACLK) begin
        if (!ARESETN) begin
            rvalid_reg <= 1'b0;
            rresp_reg  <= 2'b00;
            rdata_reg  <= {DATA_WIDTH{1'b0}};
        end else begin
            if (arready_reg && ARVALID) begin
                case (ARADDR[3:2])
                    2'b00: rdata_reg <= in_reg;
                    2'b01: rdata_reg <= {15'b0, en_reg};
                    2'b10: rdata_reg <= pipe[3];
                    2'b11: rdata_reg <= pipe[2];
                    default: rdata_reg <= {DATA_WIDTH{1'b0}};
                endcase
                rvalid_reg <= 1'b1;
                rresp_reg  <= 2'b00; // OKAY
            end else if (rvalid_reg && RREADY) begin
                rvalid_reg <= 1'b0;
            end
        end
    end

    // Pipeline Logic
    function integer log2_func;
        input [15:0] value;
        begin
            casex (value)
                16'b1??????????????? : log2_func = 15;
                16'b01?????????????? : log2_func = 14;
                16'b001????????????? : log2_func = 13;
                16'b0001???????????? : log2_func = 12;
                16'b00001??????????? : log2_func = 11;
                16'b000001?????????? : log2_func = 10;
                16'b0000001????????? : log2_func = 9;
                16'b00000001???????? : log2_func = 8;
                16'b000000001??????? : log2_func = 7;
                16'b0000000001?????? : log2_func = 6;
                16'b00000000001????? : log2_func = 5;
                16'b000000000001???? : log2_func = 4;
                16'b0000000000001??? : log2_func = 3;
                16'b00000000000001?? : log2_func = 2;
                16'b000000000000001? : log2_func = 1;
                16'b0000000000000001 : log2_func = 0;
                default             : log2_func = 0;
            endcase
        end
    endfunction

    integer i;
    always @(posedge ACLK) begin
        if (!ARESETN) begin
            for (i = 0; i < 4; i = i + 1)
                pipe[i] <= {DATA_WIDTH{1'b0}};
        end else begin
            if (en_reg) begin
                pipe[3] <= pipe[2];
                pipe[2] <= pipe[1];
                pipe[1] <= pipe[0];
                pipe[0] <= in_reg + log2_func(in_reg);
            end
        end
    end

endmodule
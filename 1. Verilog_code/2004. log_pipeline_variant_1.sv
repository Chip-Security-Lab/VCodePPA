//SystemVerilog
module log_pipeline_axi4lite #(
    parameter ADDR_WIDTH = 4,         // Address width for mapping registers
    parameter DATA_WIDTH = 16         // Data width for AXI4-Lite
)(
    input                   clk,
    input                   reset_n,
    // AXI4-Lite Write Address Channel
    input  [ADDR_WIDTH-1:0] s_axi_awaddr,
    input                   s_axi_awvalid,
    output                  s_axi_awready,
    // AXI4-Lite Write Data Channel
    input  [DATA_WIDTH-1:0] s_axi_wdata,
    input  [(DATA_WIDTH/8)-1:0] s_axi_wstrb,
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
    output [DATA_WIDTH-1:0] s_axi_rdata,
    output [1:0]            s_axi_rresp,
    output                  s_axi_rvalid,
    input                   s_axi_rready
);

    // Internal registers
    reg [DATA_WIDTH-1:0] pipe [0:3];
    reg [DATA_WIDTH-1:0] reg_in;
    reg                  reg_en;

    // AXI4-Lite handshake signals
    reg                  awready_reg, wready_reg, bvalid_reg, arready_reg, rvalid_reg;
    reg [1:0]            bresp_reg, rresp_reg;
    reg [DATA_WIDTH-1:0] rdata_reg_comb, rdata_reg_out;
    reg                  rvalid_reg_d, rvalid_reg_q;
    reg [1:0]            rresp_reg_d, rresp_reg_q;

    assign s_axi_awready = awready_reg;
    assign s_axi_wready  = wready_reg;
    assign s_axi_bvalid  = bvalid_reg;
    assign s_axi_bresp   = bresp_reg;
    assign s_axi_arready = arready_reg;
    assign s_axi_rvalid  = rvalid_reg_q;
    assign s_axi_rdata   = rdata_reg_out;
    assign s_axi_rresp   = rresp_reg_q;

    // AXI4-Lite address mapping
    localparam ADDR_IN    = 4'h0;  // Write: input data
    localparam ADDR_EN    = 4'h4;  // Write: enable
    localparam ADDR_OUT   = 4'h8;  // Read: output
    localparam ADDR_PIPE0 = 4'hC;  // Read: pipe[0]
    localparam ADDR_PIPE1 = 4'h10; // Read: pipe[1]
    localparam ADDR_PIPE2 = 4'h14; // Read: pipe[2]
    localparam ADDR_PIPE3 = 4'h18; // Read: pipe[3]

    // Control write address and write data acceptance
    reg aw_en;
    always @(posedge clk or negedge reset_n) begin
        if (!reset_n) begin
            awready_reg <= 1'b0;
            wready_reg  <= 1'b0;
            aw_en       <= 1'b1;
        end else begin
            if (s_axi_awvalid && s_axi_wvalid && aw_en) begin
                awready_reg <= 1'b1;
                wready_reg  <= 1'b1;
                aw_en       <= 1'b0;
            end else if (bvalid_reg && s_axi_bready) begin
                awready_reg <= 1'b0;
                wready_reg  <= 1'b0;
                aw_en       <= 1'b1;
            end else begin
                awready_reg <= 1'b0;
                wready_reg  <= 1'b0;
            end
        end
    end

    // Write operation
    always @(posedge clk or negedge reset_n) begin
        if (!reset_n) begin
            reg_in <= {DATA_WIDTH{1'b0}};
            reg_en <= 1'b0;
        end else if (s_axi_awvalid && s_axi_wvalid && aw_en && awready_reg && wready_reg) begin
            case (s_axi_awaddr)
                ADDR_IN: begin
                    reg_in <= s_axi_wdata;
                end
                ADDR_EN: begin
                    reg_en <= s_axi_wdata[0];
                end
                default: ;
            endcase
        end
    end

    // Write response logic
    always @(posedge clk or negedge reset_n) begin
        if (!reset_n) begin
            bvalid_reg <= 1'b0;
            bresp_reg  <= 2'b00;
        end else begin
            if (awready_reg && wready_reg && !bvalid_reg) begin
                bvalid_reg <= 1'b1;
                bresp_reg  <= 2'b00; // OKAY
            end else if (bvalid_reg && s_axi_bready) begin
                bvalid_reg <= 1'b0;
            end
        end
    end

    // Read address acceptance
    always @(posedge clk or negedge reset_n) begin
        if (!reset_n) begin
            arready_reg <= 1'b0;
        end else begin
            if (s_axi_arvalid && !arready_reg && !rvalid_reg_q) begin
                arready_reg <= 1'b1;
            end else begin
                arready_reg <= 1'b0;
            end
        end
    end

    // Pipeline logic (core functionality)
    function integer log2_optimized;
        input [15:0] value;
        begin
            if      (value[15]) log2_optimized = 15;
            else if (value[14]) log2_optimized = 14;
            else if (value[13]) log2_optimized = 13;
            else if (value[12]) log2_optimized = 12;
            else if (value[11]) log2_optimized = 11;
            else if (value[10]) log2_optimized = 10;
            else if (value[9])  log2_optimized = 9;
            else if (value[8])  log2_optimized = 8;
            else if (value[7])  log2_optimized = 7;
            else if (value[6])  log2_optimized = 6;
            else if (value[5])  log2_optimized = 5;
            else if (value[4])  log2_optimized = 4;
            else if (value[3])  log2_optimized = 3;
            else if (value[2])  log2_optimized = 2;
            else if (value[1])  log2_optimized = 1;
            else                log2_optimized = 0;
        end
    endfunction

    // Pipeline input register and combinational logic
    reg [DATA_WIDTH-1:0] pipe0_in, pipe1_in, pipe2_in, pipe3_in;
    reg                  reg_en_d1, reg_en_d2, reg_en_d3;

    always @(posedge clk or negedge reset_n) begin
        if (!reset_n) begin
            reg_en_d1 <= 1'b0;
            reg_en_d2 <= 1'b0;
            reg_en_d3 <= 1'b0;
        end else begin
            reg_en_d1 <= reg_en;
            reg_en_d2 <= reg_en_d1;
            reg_en_d3 <= reg_en_d2;
        end
    end

    always @(*) begin
        pipe0_in = reg_in + log2_optimized(reg_in);
        pipe1_in = pipe[0];
        pipe2_in = pipe[1];
        pipe3_in = pipe[2];
    end

    integer i;
    always @(posedge clk or negedge reset_n) begin
        if (!reset_n) begin
            for (i = 0; i < 4; i = i + 1)
                pipe[i] <= {DATA_WIDTH{1'b0}};
        end else begin
            if (reg_en) begin
                pipe[0] <= pipe0_in;
            end
            if (reg_en_d1) begin
                pipe[1] <= pipe1_in;
            end
            if (reg_en_d2) begin
                pipe[2] <= pipe2_in;
            end
            if (reg_en_d3) begin
                pipe[3] <= pipe3_in;
            end
        end
    end

    // Output register for rvalid/rresp/rdata
    always @(*) begin
        rdata_reg_comb = {DATA_WIDTH{1'b0}};
        rresp_reg_d = 2'b00;
        rvalid_reg_d = 1'b0;
        if (s_axi_arvalid && arready_reg && !rvalid_reg_q) begin
            rvalid_reg_d = 1'b1;
            rresp_reg_d = 2'b00; // OKAY
            case (s_axi_araddr)
                ADDR_OUT:    rdata_reg_comb = pipe[3];
                ADDR_PIPE0:  rdata_reg_comb = pipe[0];
                ADDR_PIPE1:  rdata_reg_comb = pipe[1];
                ADDR_PIPE2:  rdata_reg_comb = pipe[2];
                ADDR_PIPE3:  rdata_reg_comb = pipe[3];
                ADDR_IN:     rdata_reg_comb = reg_in;
                ADDR_EN:     rdata_reg_comb = {15'b0, reg_en};
                default:     rdata_reg_comb = {DATA_WIDTH{1'b0}};
            endcase
        end
    end

    always @(posedge clk or negedge reset_n) begin
        if (!reset_n) begin
            rvalid_reg_q   <= 1'b0;
            rresp_reg_q    <= 2'b00;
            rdata_reg_out  <= {DATA_WIDTH{1'b0}};
        end else begin
            if (rvalid_reg_q && s_axi_rready) begin
                rvalid_reg_q   <= 1'b0;
            end else if (rvalid_reg_d) begin
                rvalid_reg_q   <= 1'b1;
            end

            if (rvalid_reg_d) begin
                rresp_reg_q    <= rresp_reg_d;
                rdata_reg_out  <= rdata_reg_comb;
            end
        end
    end

endmodule
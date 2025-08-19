//SystemVerilog
module multi_clock_shifter_axi4lite #(
    parameter ADDR_WIDTH = 4
)(
    input                   ACLK,
    input                   ARESETn,
    // AXI4-Lite Write Address Channel
    input  [ADDR_WIDTH-1:0] S_AXI_AWADDR,
    input                   S_AXI_AWVALID,
    output                  S_AXI_AWREADY,
    // AXI4-Lite Write Data Channel
    input  [7:0]            S_AXI_WDATA,
    input  [0:0]            S_AXI_WSTRB,
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
    output [7:0]            S_AXI_RDATA,
    output [1:0]            S_AXI_RRESP,
    output                  S_AXI_RVALID,
    input                   S_AXI_RREADY
);

    // Internal registers for AXI4-Lite mapped registers
    reg [7:0]   reg_data_in;
    reg [2:0]   reg_shift_a;
    reg [2:0]   reg_shift_b;
    reg         reg_valid_in;
    reg [7:0]   reg_data_out;
    reg         reg_valid_out;

    // Internal pipeline registers
    reg [7:0]   data_in_stage1;
    reg [2:0]   shift_a_stage1;
    reg [2:0]   shift_b_stage1;
    reg         valid_stage1;

    reg [7:0]   shift_left_stage2;
    reg [2:0]   shift_b_stage2;
    reg         valid_stage2;

    // CDC registers
    reg [7:0]   cdc_data;
    reg [2:0]   cdc_shift_b;
    reg         cdc_valid;
    reg [7:0]   cdc_data_b;
    reg [2:0]   cdc_shift_b_b;
    reg         cdc_valid_b;

    reg [7:0]   shift_right_stage3;
    reg         valid_stage3;

    // AXI4-Lite FSM states
    localparam  IDLE = 2'd0,
                WRITE = 2'd1,
                WRITE_RESP = 2'd2,
                READ = 2'd1;

    // Write address handshake
    reg         axi_awready;
    reg         axi_wready;
    reg [1:0]   axi_bresp;
    reg         axi_bvalid;

    // Read address handshake
    reg         axi_arready;
    reg [7:0]   axi_rdata;
    reg [1:0]   axi_rresp;
    reg         axi_rvalid;

    // AXI4-Lite address latching
    reg [ADDR_WIDTH-1:0]    axi_awaddr;
    reg [ADDR_WIDTH-1:0]    axi_araddr;

    // Assign AXI4-Lite outputs
    assign S_AXI_AWREADY = axi_awready;
    assign S_AXI_WREADY  = axi_wready;
    assign S_AXI_BRESP   = axi_bresp;
    assign S_AXI_BVALID  = axi_bvalid;
    assign S_AXI_ARREADY = axi_arready;
    assign S_AXI_RDATA   = axi_rdata;
    assign S_AXI_RRESP   = axi_rresp;
    assign S_AXI_RVALID  = axi_rvalid;

    // AXI4-Lite write address latch
    always @(posedge ACLK or negedge ARESETn) begin
        if (!ARESETn) begin
            axi_awready <= 1'b0;
            axi_awaddr <= {ADDR_WIDTH{1'b0}};
        end else if (!axi_awready && S_AXI_AWVALID && S_AXI_WVALID) begin
            axi_awready <= 1'b1;
            axi_awaddr <= S_AXI_AWADDR;
        end else begin
            axi_awready <= 1'b0;
        end
    end

    // AXI4-Lite write data latch
    always @(posedge ACLK or negedge ARESETn) begin
        if (!ARESETn) begin
            axi_wready <= 1'b0;
        end else if (!axi_wready && S_AXI_AWVALID && S_AXI_WVALID) begin
            axi_wready <= 1'b1;
        end else begin
            axi_wready <= 1'b0;
        end
    end

    // AXI4-Lite write response logic
    always @(posedge ACLK or negedge ARESETn) begin
        if (!ARESETn) begin
            axi_bvalid <= 1'b0;
            axi_bresp  <= 2'b00;
        end else if (axi_awready && S_AXI_AWVALID && axi_wready && S_AXI_WVALID && !axi_bvalid) begin
            axi_bvalid <= 1'b1;
            axi_bresp  <= 2'b00; // OKAY
        end else if (S_AXI_BREADY && axi_bvalid) begin
            axi_bvalid <= 1'b0;
        end
    end

    // AXI4-Lite read address latch
    always @(posedge ACLK or negedge ARESETn) begin
        if (!ARESETn) begin
            axi_arready <= 1'b0;
            axi_araddr <= {ADDR_WIDTH{1'b0}};
        end else if (!axi_arready && S_AXI_ARVALID) begin
            axi_arready <= 1'b1;
            axi_araddr <= S_AXI_ARADDR;
        end else begin
            axi_arready <= 1'b0;
        end
    end

    // AXI4-Lite read data logic
    always @(posedge ACLK or negedge ARESETn) begin
        if (!ARESETn) begin
            axi_rvalid <= 1'b0;
            axi_rresp  <= 2'b00;
            axi_rdata  <= 8'd0;
        end else if (axi_arready && S_AXI_ARVALID && !axi_rvalid) begin
            axi_rvalid <= 1'b1;
            axi_rresp  <= 2'b00;
            case (axi_araddr[3:0])
                4'h0: axi_rdata <= reg_data_in;
                4'h1: axi_rdata <= {5'd0, reg_shift_a};
                4'h2: axi_rdata <= {5'd0, reg_shift_b};
                4'h3: axi_rdata <= {7'd0, reg_valid_in};
                4'h4: axi_rdata <= reg_data_out;
                4'h5: axi_rdata <= {7'd0, reg_valid_out};
                default: axi_rdata <= 8'd0;
            endcase
        end else if (axi_rvalid && S_AXI_RREADY) begin
            axi_rvalid <= 1'b0;
        end
    end

    // AXI4-Lite register write logic
    always @(posedge ACLK or negedge ARESETn) begin
        if (!ARESETn) begin
            reg_data_in  <= 8'd0;
            reg_shift_a  <= 3'd0;
            reg_shift_b  <= 3'd0;
            reg_valid_in <= 1'b0;
        end else if (axi_awready && S_AXI_AWVALID && axi_wready && S_AXI_WVALID) begin
            case (axi_awaddr[3:0])
                4'h0: if (S_AXI_WSTRB[0]) reg_data_in  <= S_AXI_WDATA;
                4'h1: if (S_AXI_WSTRB[0]) reg_shift_a  <= S_AXI_WDATA[2:0];
                4'h2: if (S_AXI_WSTRB[0]) reg_shift_b  <= S_AXI_WDATA[2:0];
                4'h3: if (S_AXI_WSTRB[0]) reg_valid_in <= S_AXI_WDATA[0];
                default: ;
            endcase
        end
    end

    // Main datapath (all in ACLK domain)
    always @(posedge ACLK or negedge ARESETn) begin
        if (!ARESETn) begin
            data_in_stage1   <= 8'd0;
            shift_a_stage1   <= 3'd0;
            shift_b_stage1   <= 3'd0;
            valid_stage1     <= 1'b0;
        end else begin
            data_in_stage1   <= reg_data_in;
            shift_a_stage1   <= reg_shift_a;
            shift_b_stage1   <= reg_shift_b;
            valid_stage1     <= reg_valid_in;
        end
    end

    always @(posedge ACLK or negedge ARESETn) begin
        if (!ARESETn) begin
            shift_left_stage2 <= 8'd0;
            shift_b_stage2    <= 3'd0;
            valid_stage2      <= 1'b0;
        end else begin
            shift_left_stage2 <= data_in_stage1 << shift_a_stage1;
            shift_b_stage2    <= shift_b_stage1;
            valid_stage2      <= valid_stage1;
        end
    end

    always @(posedge ACLK or negedge ARESETn) begin
        if (!ARESETn) begin
            cdc_data    <= 8'd0;
            cdc_shift_b <= 3'd0;
            cdc_valid   <= 1'b0;
        end else begin
            cdc_data    <= shift_left_stage2;
            cdc_shift_b <= shift_b_stage2;
            cdc_valid   <= valid_stage2;
        end
    end

    always @(posedge ACLK or negedge ARESETn) begin
        if (!ARESETn) begin
            cdc_data_b     <= 8'd0;
            cdc_shift_b_b  <= 3'd0;
            cdc_valid_b    <= 1'b0;
        end else begin
            cdc_data_b     <= cdc_data;
            cdc_shift_b_b  <= cdc_shift_b;
            cdc_valid_b    <= cdc_valid;
        end
    end

    always @(posedge ACLK or negedge ARESETn) begin
        if (!ARESETn) begin
            shift_right_stage3 <= 8'd0;
            valid_stage3       <= 1'b0;
        end else begin
            shift_right_stage3 <= cdc_data_b >> cdc_shift_b_b;
            valid_stage3       <= cdc_valid_b;
        end
    end

    always @(posedge ACLK or negedge ARESETn) begin
        if (!ARESETn) begin
            reg_data_out  <= 8'd0;
            reg_valid_out <= 1'b0;
        end else begin
            reg_data_out  <= shift_right_stage3;
            reg_valid_out <= valid_stage3;
        end
    end

endmodule
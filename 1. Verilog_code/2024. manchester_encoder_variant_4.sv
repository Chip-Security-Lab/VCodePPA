//SystemVerilog
module manchester_encoder_axi4lite #(
    parameter ADDR_WIDTH = 4,
    parameter DATA_WIDTH = 32
)(
    input                       clk,
    input                       rst_n,
    // AXI4-Lite Write Address Channel
    input      [ADDR_WIDTH-1:0] s_axi_awaddr,
    input                       s_axi_awvalid,
    output                      s_axi_awready,
    // AXI4-Lite Write Data Channel
    input      [DATA_WIDTH-1:0] s_axi_wdata,
    input      [(DATA_WIDTH/8)-1:0] s_axi_wstrb,
    input                       s_axi_wvalid,
    output                      s_axi_wready,
    // AXI4-Lite Write Response Channel
    output     [1:0]            s_axi_bresp,
    output                      s_axi_bvalid,
    input                       s_axi_bready,
    // AXI4-Lite Read Address Channel
    input      [ADDR_WIDTH-1:0] s_axi_araddr,
    input                       s_axi_arvalid,
    output                      s_axi_arready,
    // AXI4-Lite Read Data Channel
    output     [DATA_WIDTH-1:0] s_axi_rdata,
    output     [1:0]            s_axi_rresp,
    output                      s_axi_rvalid,
    input                       s_axi_rready
);

    // Register Map
    localparam REG_DATA_IN      = 4'h0;
    localparam REG_ENCODED_OUT  = 4'h4;

    // Internal registers
    reg data_in_reg;
    reg encoded_out_reg;
    reg data_reg;

    // Write FSM
    reg aw_en;

    // Wires for channel handshakes and data
    wire axi_aw_ready;
    wire axi_w_ready;
    wire [1:0] axi_b_resp;
    wire axi_b_valid;
    wire axi_ar_ready;
    wire [DATA_WIDTH-1:0] axi_r_data;
    wire [1:0] axi_r_resp;
    wire axi_r_valid;

    // Write Address and Write Data Channel Handler
    axi4lite_write_channel #(
        .ADDR_WIDTH(ADDR_WIDTH),
        .DATA_WIDTH(DATA_WIDTH)
    ) u_axi4lite_write_channel (
        .clk           (clk),
        .rst_n         (rst_n),
        .s_axi_awaddr  (s_axi_awaddr),
        .s_axi_awvalid (s_axi_awvalid),
        .s_axi_awready (axi_aw_ready),
        .s_axi_wdata   (s_axi_wdata),
        .s_axi_wstrb   (s_axi_wstrb),
        .s_axi_wvalid  (s_axi_wvalid),
        .s_axi_wready  (axi_w_ready),
        .s_axi_bresp   (axi_b_resp),
        .s_axi_bvalid  (axi_b_valid),
        .s_axi_bready  (s_axi_bready),
        .aw_en         (aw_en)
    );

    assign s_axi_awready = axi_aw_ready;
    assign s_axi_wready  = axi_w_ready;
    assign s_axi_bresp   = axi_b_resp;
    assign s_axi_bvalid  = axi_b_valid;

    // Write logic
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            data_in_reg <= 1'b0;
        end else if (axi_aw_ready && s_axi_awvalid && axi_w_ready && s_axi_wvalid) begin
            if (s_axi_awaddr[ADDR_WIDTH-1:0] == REG_DATA_IN) begin
                data_in_reg <= s_axi_wdata[0];
            end
        end
    end

    // Read Address and Read Data Channel Handler
    axi4lite_read_channel #(
        .ADDR_WIDTH(ADDR_WIDTH),
        .DATA_WIDTH(DATA_WIDTH)
    ) u_axi4lite_read_channel (
        .clk           (clk),
        .rst_n         (rst_n),
        .s_axi_araddr  (s_axi_araddr),
        .s_axi_arvalid (s_axi_arvalid),
        .s_axi_arready (axi_ar_ready),
        .s_axi_rdata   (axi_r_data),
        .s_axi_rresp   (axi_r_resp),
        .s_axi_rvalid  (axi_r_valid),
        .s_axi_rready  (s_axi_rready),
        .reg_data_in   (data_in_reg),
        .reg_encoded_out(encoded_out_reg)
    );

    assign s_axi_arready = axi_ar_ready;
    assign s_axi_rdata   = axi_r_data;
    assign s_axi_rresp   = axi_r_resp;
    assign s_axi_rvalid  = axi_r_valid;

    // Manchester Encoder Logic
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

// AXI4-Lite Write Channel Handler
module axi4lite_write_channel #(
    parameter ADDR_WIDTH = 4,
    parameter DATA_WIDTH = 32
)(
    input                       clk,
    input                       rst_n,
    input      [ADDR_WIDTH-1:0] s_axi_awaddr,
    input                       s_axi_awvalid,
    output reg                  s_axi_awready,
    input      [DATA_WIDTH-1:0] s_axi_wdata,
    input      [(DATA_WIDTH/8)-1:0] s_axi_wstrb,
    input                       s_axi_wvalid,
    output reg                  s_axi_wready,
    output reg [1:0]            s_axi_bresp,
    output reg                  s_axi_bvalid,
    input                       s_axi_bready,
    output reg                  aw_en
);
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            s_axi_awready <= 1'b0;
            aw_en         <= 1'b1;
        end else begin
            if (~s_axi_awready && s_axi_awvalid && s_axi_wvalid && aw_en) begin
                s_axi_awready <= 1'b1;
                aw_en <= 1'b0;
            end else if (s_axi_bready && s_axi_bvalid) begin
                aw_en <= 1'b1;
                s_axi_awready <= 1'b0;
            end else begin
                s_axi_awready <= 1'b0;
            end
        end
    end

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            s_axi_wready <= 1'b0;
        end else begin
            if (~s_axi_wready && s_axi_awvalid && s_axi_wvalid && aw_en) begin
                s_axi_wready <= 1'b1;
            end else begin
                s_axi_wready <= 1'b0;
            end
        end
    end

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            s_axi_bvalid <= 1'b0;
            s_axi_bresp  <= 2'b00;
        end else begin
            if (s_axi_awready && s_axi_awvalid && s_axi_wready && s_axi_wvalid) begin
                s_axi_bvalid <= 1'b1;
                s_axi_bresp  <= 2'b00; // OKAY
            end else if (s_axi_bvalid && s_axi_bready) begin
                s_axi_bvalid <= 1'b0;
            end
        end
    end
endmodule

// AXI4-Lite Read Channel Handler
module axi4lite_read_channel #(
    parameter ADDR_WIDTH = 4,
    parameter DATA_WIDTH = 32
)(
    input                       clk,
    input                       rst_n,
    input      [ADDR_WIDTH-1:0] s_axi_araddr,
    input                       s_axi_arvalid,
    output reg                  s_axi_arready,
    output reg [DATA_WIDTH-1:0] s_axi_rdata,
    output reg [1:0]            s_axi_rresp,
    output reg                  s_axi_rvalid,
    input                       s_axi_rready,
    input                       reg_data_in,
    input                       reg_encoded_out
);

    localparam REG_DATA_IN      = 4'h0;
    localparam REG_ENCODED_OUT  = 4'h4;

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            s_axi_arready <= 1'b0;
        end else begin
            if (~s_axi_arready && s_axi_arvalid) begin
                s_axi_arready <= 1'b1;
            end else begin
                s_axi_arready <= 1'b0;
            end
        end
    end

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            s_axi_rvalid <= 1'b0;
            s_axi_rresp  <= 2'b00;
            s_axi_rdata  <= {DATA_WIDTH{1'b0}};
        end else begin
            if (s_axi_arready && s_axi_arvalid) begin
                s_axi_rvalid <= 1'b1;
                s_axi_rresp  <= 2'b00; // OKAY
                case (s_axi_araddr[ADDR_WIDTH-1:0])
                    REG_DATA_IN:     s_axi_rdata <= {{(DATA_WIDTH-1){1'b0}}, reg_data_in};
                    REG_ENCODED_OUT: s_axi_rdata <= {{(DATA_WIDTH-1){1'b0}}, reg_encoded_out};
                    default:         s_axi_rdata <= {DATA_WIDTH{1'b0}};
                endcase
            end else if (s_axi_rvalid && s_axi_rready) begin
                s_axi_rvalid <= 1'b0;
            end
        end
    end
endmodule
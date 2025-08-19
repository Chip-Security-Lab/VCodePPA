//SystemVerilog
module var_dir_shifter_axi4lite #(
    parameter ADDR_WIDTH = 4,    // 16 bytes addressable space
    parameter DATA_WIDTH = 16
)(
    input                       clk,
    input                       rst_n,

    // AXI4-Lite Write Address Channel
    input  [ADDR_WIDTH-1:0]     s_axi_awaddr,
    input                       s_axi_awvalid,
    output reg                  s_axi_awready,

    // AXI4-Lite Write Data Channel
    input  [DATA_WIDTH-1:0]     s_axi_wdata,
    input  [(DATA_WIDTH/8)-1:0] s_axi_wstrb,
    input                       s_axi_wvalid,
    output reg                  s_axi_wready,

    // AXI4-Lite Write Response Channel
    output reg [1:0]            s_axi_bresp,
    output reg                  s_axi_bvalid,
    input                       s_axi_bready,

    // AXI4-Lite Read Address Channel
    input  [ADDR_WIDTH-1:0]     s_axi_araddr,
    input                       s_axi_arvalid,
    output reg                  s_axi_arready,

    // AXI4-Lite Read Data Channel
    output reg [DATA_WIDTH-1:0] s_axi_rdata,
    output reg [1:0]            s_axi_rresp,
    output reg                  s_axi_rvalid,
    input                       s_axi_rready
);

    // Register Map
    // 0x0: in_data [15:0]         (RW)
    // 0x2: shift_amount [3:0]     (RW)
    // 0x3: direction [0]          (RW)
    // 0x4: fill_value [0]         (RW)
    // 0x6: out_data [15:0]        (RO)

    reg [15:0] reg_in_data;
    reg [3:0]  reg_shift_amount;
    reg        reg_direction;
    reg        reg_fill_value;

    reg [15:0] reg_out_data;

    // Internal state
    reg aw_en;
    reg ar_en;

    // Forwarded signals (front-end register retiming)
    reg [ADDR_WIDTH-1:0] awaddr_d;
    reg [ADDR_WIDTH-1:0] araddr_d;
    reg                  awvalid_d;
    reg                  arvalid_d;
    reg [DATA_WIDTH-1:0] wdata_d;
    reg [(DATA_WIDTH/8)-1:0] wstrb_d;
    reg                  wvalid_d;

    // Write Address handshake - move register after combinational handshake logic
    wire aw_handshake = s_axi_awvalid && aw_en && !s_axi_awready;
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            s_axi_awready <= 1'b0;
            aw_en <= 1'b1;
            awaddr_d <= {ADDR_WIDTH{1'b0}};
            awvalid_d <= 1'b0;
        end else begin
            if (aw_handshake) begin
                s_axi_awready <= 1'b1;
                awaddr_d <= s_axi_awaddr;
                awvalid_d <= 1'b1;
            end else begin
                s_axi_awready <= 1'b0;
                if (s_axi_bvalid && s_axi_bready)
                    awvalid_d <= 1'b0;
            end

            if (s_axi_bvalid && s_axi_bready)
                aw_en <= 1'b1;
            else if (aw_handshake)
                aw_en <= 1'b0;
        end
    end

    // Write Data handshake - register after handshake
    wire w_handshake = s_axi_wvalid && aw_en && !s_axi_wready;
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            s_axi_wready <= 1'b0;
            wdata_d <= {DATA_WIDTH{1'b0}};
            wstrb_d <= {(DATA_WIDTH/8){1'b0}};
            wvalid_d <= 1'b0;
        end else begin
            if (w_handshake) begin
                s_axi_wready <= 1'b1;
                wdata_d <= s_axi_wdata;
                wstrb_d <= s_axi_wstrb;
                wvalid_d <= 1'b1;
            end else begin
                s_axi_wready <= 1'b0;
                if (s_axi_bvalid && s_axi_bready)
                    wvalid_d <= 1'b0;
            end
        end
    end

    // Write operation - use registered address/data after handshake
    wire write_en = awvalid_d && wvalid_d && !s_axi_bvalid;
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            reg_in_data      <= 16'd0;
            reg_shift_amount <= 4'd0;
            reg_direction    <= 1'b0;
            reg_fill_value   <= 1'b0;
        end else if (write_en) begin
            case (awaddr_d)
                4'h0, 4'h1: begin // in_data
                    if (wstrb_d[1]) reg_in_data[15:8] <= wdata_d[15:8];
                    if (wstrb_d[0]) reg_in_data[7:0]  <= wdata_d[7:0];
                end
                4'h2: begin // shift_amount
                    if (wstrb_d[0]) reg_shift_amount <= wdata_d[3:0];
                end
                4'h3: begin // direction
                    if (wstrb_d[0]) reg_direction <= wdata_d[0];
                end
                4'h4: begin // fill_value
                    if (wstrb_d[0]) reg_fill_value <= wdata_d[0];
                end
                default: ;
            endcase
        end
    end

    // Write Response channel
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            s_axi_bvalid <= 1'b0;
            s_axi_bresp  <= 2'b00;
        end else begin
            if (write_en) begin
                s_axi_bvalid <= 1'b1;
                s_axi_bresp  <= 2'b00;
            end else if (s_axi_bvalid && s_axi_bready)
                s_axi_bvalid <= 1'b0;
        end
    end

    // Read Address handshake - move register after combinational handshake logic
    wire ar_handshake = s_axi_arvalid && ar_en && !s_axi_arready;
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            s_axi_arready <= 1'b0;
            ar_en <= 1'b1;
            araddr_d <= {ADDR_WIDTH{1'b0}};
            arvalid_d <= 1'b0;
        end else begin
            if (ar_handshake) begin
                s_axi_arready <= 1'b1;
                araddr_d <= s_axi_araddr;
                arvalid_d <= 1'b1;
            end else begin
                s_axi_arready <= 1'b0;
                if (s_axi_rvalid && s_axi_rready)
                    arvalid_d <= 1'b0;
            end

            if (s_axi_rvalid && s_axi_rready)
                ar_en <= 1'b1;
            else if (ar_handshake)
                ar_en <= 1'b0;
        end
    end

    // Read Data channel - use registered address after handshake
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            s_axi_rvalid <= 1'b0;
            s_axi_rresp  <= 2'b00;
            s_axi_rdata  <= 16'd0;
        end else begin
            if (arvalid_d && !s_axi_rvalid) begin
                s_axi_rvalid <= 1'b1;
                s_axi_rresp  <= 2'b00;
                case (araddr_d)
                    4'h0, 4'h1: s_axi_rdata <= reg_in_data;
                    4'h2:      s_axi_rdata <= {12'd0, reg_shift_amount};
                    4'h3:      s_axi_rdata <= {15'd0, reg_direction};
                    4'h4:      s_axi_rdata <= {15'd0, reg_fill_value};
                    4'h6, 4'h7: s_axi_rdata <= reg_out_data;
                    default:   s_axi_rdata <= 16'd0;
                endcase
            end else if (s_axi_rvalid && s_axi_rready)
                s_axi_rvalid <= 1'b0;
        end
    end

    // Shifter Core Logic, update reg_out_data on any parameter change
    integer i;
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n)
            reg_out_data <= 16'd0;
        else begin
            reg_out_data = reg_in_data;
            if (reg_direction) begin // Left shift
                for (i = 0; i < reg_shift_amount; i = i + 1)
                    reg_out_data = {reg_out_data[14:0], reg_fill_value};
            end else begin // Right shift
                for (i = 0; i < reg_shift_amount; i = i + 1)
                    reg_out_data = {reg_fill_value, reg_out_data[15:1]};
            end
        end
    end

endmodule
//SystemVerilog
module onehot_mux_axi4lite #(
    parameter ADDR_WIDTH = 4,    // Address width for 4 registers
    parameter DATA_WIDTH = 8     // Data width
)(
    // AXI4-Lite clock and reset
    input  wire                   s_axi_aclk,
    input  wire                   s_axi_aresetn,

    // AXI4-Lite write address channel
    input  wire [ADDR_WIDTH-1:0]  s_axi_awaddr,
    input  wire                   s_axi_awvalid,
    output reg                    s_axi_awready,

    // AXI4-Lite write data channel
    input  wire [DATA_WIDTH-1:0]  s_axi_wdata,
    input  wire [(DATA_WIDTH/8)-1:0] s_axi_wstrb,
    input  wire                   s_axi_wvalid,
    output reg                    s_axi_wready,

    // AXI4-Lite write response channel
    output reg [1:0]              s_axi_bresp,
    output reg                    s_axi_bvalid,
    input  wire                   s_axi_bready,

    // AXI4-Lite read address channel
    input  wire [ADDR_WIDTH-1:0]  s_axi_araddr,
    input  wire                   s_axi_arvalid,
    output reg                    s_axi_arready,

    // AXI4-Lite read data channel
    output reg [DATA_WIDTH-1:0]   s_axi_rdata,
    output reg [1:0]              s_axi_rresp,
    output reg                    s_axi_rvalid,
    input  wire                   s_axi_rready
);

    // Internal registers for inputs and selection
    reg [3:0] one_hot_sel_reg;
    reg [7:0] in0_reg, in1_reg, in2_reg, in3_reg;
    wire [7:0] data_out_wire;

    // Address mapping
    localparam ADDR_SEL  = 4'h0;
    localparam ADDR_IN0  = 4'h4;
    localparam ADDR_IN1  = 4'h8;
    localparam ADDR_IN2  = 4'hC;
    localparam ADDR_IN3  = 4'h10;
    localparam ADDR_OUT  = 4'h14;

    // AXI4-Lite write FSM
    reg aw_en;
    always @(posedge s_axi_aclk) begin
        if (!s_axi_aresetn) begin
            s_axi_awready <= 1'b0;
            s_axi_wready  <= 1'b0;
            aw_en         <= 1'b1;
        end else begin
            if (~s_axi_awready && s_axi_awvalid && ~s_axi_wready && s_axi_wvalid && aw_en) begin
                s_axi_awready <= 1'b1;
                s_axi_wready  <= 1'b1;
            end else if (s_axi_bvalid && s_axi_bready) begin
                aw_en         <= 1'b1;
                s_axi_awready <= 1'b0;
                s_axi_wready  <= 1'b0;
            end else begin
                s_axi_awready <= 1'b0;
                s_axi_wready  <= 1'b0;
            end
        end
    end

    // Optimized write logic with address range check
    always @(posedge s_axi_aclk) begin
        if (!s_axi_aresetn) begin
            one_hot_sel_reg <= 4'b0001;
            in0_reg         <= 8'b0;
            in1_reg         <= 8'b0;
            in2_reg         <= 8'b0;
            in3_reg         <= 8'b0;
        end else begin
            if (s_axi_awready && s_axi_awvalid && s_axi_wready && s_axi_wvalid) begin
                if (s_axi_awaddr == ADDR_SEL) begin
                    if (s_axi_wstrb[0]) one_hot_sel_reg <= s_axi_wdata[3:0];
                end else if (s_axi_awaddr >= ADDR_IN0 && s_axi_awaddr <= ADDR_IN3 && ((s_axi_awaddr & 4'h3) == 0)) begin
                    case (s_axi_awaddr[3:2])
                        2'b01: if (s_axi_wstrb[0]) in0_reg <= s_axi_wdata;
                        2'b10: if (s_axi_wstrb[0]) in1_reg <= s_axi_wdata;
                        2'b11: if (s_axi_wstrb[0]) in2_reg <= s_axi_wdata;
                        2'b00: if (s_axi_wstrb[0] && (s_axi_awaddr == ADDR_IN3)) in3_reg <= s_axi_wdata;
                        default: ;
                    endcase
                end else if (s_axi_awaddr == ADDR_IN3) begin
                    if (s_axi_wstrb[0]) in3_reg <= s_axi_wdata;
                end
            end
        end
    end

    // Write response
    always @(posedge s_axi_aclk) begin
        if (!s_axi_aresetn) begin
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

    // AXI4-Lite read FSM
    always @(posedge s_axi_aclk) begin
        if (!s_axi_aresetn) begin
            s_axi_arready <= 1'b0;
            s_axi_rvalid  <= 1'b0;
            s_axi_rresp   <= 2'b00;
        end else begin
            if (!s_axi_arready && s_axi_arvalid) begin
                s_axi_arready <= 1'b1;
            end else begin
                s_axi_arready <= 1'b0;
            end

            if (s_axi_arready && s_axi_arvalid && ~s_axi_rvalid) begin
                s_axi_rvalid <= 1'b1;
                s_axi_rresp  <= 2'b00; // OKAY
            end else if (s_axi_rvalid && s_axi_rready) begin
                s_axi_rvalid <= 1'b0;
            end
        end
    end

    // Optimized read data logic with address range check
    always @(posedge s_axi_aclk) begin
        if (!s_axi_aresetn) begin
            s_axi_rdata <= {DATA_WIDTH{1'b0}};
        end else begin
            if (s_axi_arready && s_axi_arvalid) begin
                if (s_axi_araddr == ADDR_SEL) begin
                    s_axi_rdata <= {4'b0, one_hot_sel_reg};
                end else if (s_axi_araddr >= ADDR_IN0 && s_axi_araddr <= ADDR_IN3 && ((s_axi_araddr & 4'h3) == 0)) begin
                    case (s_axi_araddr[3:2])
                        2'b01: s_axi_rdata <= in0_reg;
                        2'b10: s_axi_rdata <= in1_reg;
                        2'b11: s_axi_rdata <= in2_reg;
                        2'b00: if (s_axi_araddr == ADDR_IN3) s_axi_rdata <= in3_reg; else s_axi_rdata <= {DATA_WIDTH{1'b0}};
                        default: s_axi_rdata <= {DATA_WIDTH{1'b0}};
                    endcase
                end else if (s_axi_araddr == ADDR_IN3) begin
                    s_axi_rdata <= in3_reg;
                end else if (s_axi_araddr == ADDR_OUT) begin
                    s_axi_rdata <= data_out_wire;
                end else begin
                    s_axi_rdata <= {DATA_WIDTH{1'b0}};
                end
            end
        end
    end

    // Optimized one-hot mux logic
    assign data_out_wire =
        (one_hot_sel_reg == 4'b0001) ? in0_reg :
        (one_hot_sel_reg == 4'b0010) ? in1_reg :
        (one_hot_sel_reg == 4'b0100) ? in2_reg :
        (one_hot_sel_reg == 4'b1000) ? in3_reg :
        8'b0;

endmodule
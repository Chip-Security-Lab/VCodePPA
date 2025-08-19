//SystemVerilog
`timescale 1ns / 1ps

module multi_stage_arith_shifter_axi4lite #(
    parameter ADDR_WIDTH = 4,
    parameter DATA_WIDTH = 32
)(
    input                   axi_aclk,
    input                   axi_aresetn,
    // AXI4-Lite Write Address Channel
    input  [ADDR_WIDTH-1:0] s_axi_awaddr,
    input                   s_axi_awvalid,
    output reg              s_axi_awready,
    // AXI4-Lite Write Data Channel
    input  [DATA_WIDTH-1:0] s_axi_wdata,
    input  [(DATA_WIDTH/8)-1:0] s_axi_wstrb,
    input                   s_axi_wvalid,
    output reg              s_axi_wready,
    // AXI4-Lite Write Response Channel
    output reg [1:0]        s_axi_bresp,
    output reg              s_axi_bvalid,
    input                   s_axi_bready,
    // AXI4-Lite Read Address Channel
    input  [ADDR_WIDTH-1:0] s_axi_araddr,
    input                   s_axi_arvalid,
    output reg              s_axi_arready,
    // AXI4-Lite Read Data Channel
    output reg [DATA_WIDTH-1:0] s_axi_rdata,
    output reg [1:0]        s_axi_rresp,
    output reg              s_axi_rvalid,
    input                   s_axi_rready
);

    // Address map
    localparam ADDR_IN_VALUE     = 4'h0;
    localparam ADDR_SHIFT_AMOUNT = 4'h4;
    localparam ADDR_OUT_VALUE    = 4'h8;

    // Internal registers for memory mapping
    reg [15:0] reg_in_value;
    reg [3:0]  reg_shift_amount;
    wire [15:0] shifter_out_value;

    // AXI write FSM
    reg aw_en;

    // Write address handshake
    always @(posedge axi_aclk) begin
        if (!axi_aresetn) begin
            s_axi_awready <= 1'b0;
            aw_en <= 1'b1;
        end else begin
            if (!s_axi_awready && s_axi_awvalid && s_axi_wvalid && aw_en) begin
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

    // Write data handshake
    always @(posedge axi_aclk) begin
        if (!axi_aresetn) begin
            s_axi_wready <= 1'b0;
        end else begin
            if (!s_axi_wready && s_axi_wvalid && s_axi_awvalid && aw_en) begin
                s_axi_wready <= 1'b1;
            end else begin
                s_axi_wready <= 1'b0;
            end
        end
    end

    // Write operation
    always @(posedge axi_aclk) begin
        if (!axi_aresetn) begin
            reg_in_value     <= 16'd0;
            reg_shift_amount <= 4'd0;
        end else begin
            if (s_axi_wready && s_axi_wvalid && s_axi_awready && s_axi_awvalid) begin
                case (s_axi_awaddr)
                    ADDR_IN_VALUE: begin
                        if (s_axi_wstrb[1]) reg_in_value[15:8]  <= s_axi_wdata[15:8];
                        if (s_axi_wstrb[0]) reg_in_value[7:0]   <= s_axi_wdata[7:0];
                    end
                    ADDR_SHIFT_AMOUNT: begin
                        if (s_axi_wstrb[0]) reg_shift_amount <= s_axi_wdata[3:0];
                    end
                    default: ;
                endcase
            end
        end
    end

    // Write response
    always @(posedge axi_aclk) begin
        if (!axi_aresetn) begin
            s_axi_bvalid <= 1'b0;
            s_axi_bresp  <= 2'b00;
        end else begin
            if (s_axi_awready && s_axi_awvalid && ~s_axi_bvalid && s_axi_wready && s_axi_wvalid) begin
                s_axi_bvalid <= 1'b1;
                s_axi_bresp  <= 2'b00;
            end else if (s_axi_bvalid && s_axi_bready) begin
                s_axi_bvalid <= 1'b0;
            end
        end
    end

    // Read address handshake
    always @(posedge axi_aclk) begin
        if (!axi_aresetn) begin
            s_axi_arready <= 1'b0;
        end else begin
            if (!s_axi_arready && s_axi_arvalid) begin
                s_axi_arready <= 1'b1;
            end else begin
                s_axi_arready <= 1'b0;
            end
        end
    end

    // Read data
    always @(posedge axi_aclk) begin
        if (!axi_aresetn) begin
            s_axi_rvalid <= 1'b0;
            s_axi_rresp  <= 2'b00;
            s_axi_rdata  <= {DATA_WIDTH{1'b0}};
        end else begin
            if (s_axi_arready && s_axi_arvalid && ~s_axi_rvalid) begin
                case (s_axi_araddr)
                    ADDR_IN_VALUE: begin
                        s_axi_rdata <= {16'd0, reg_in_value};
                    end
                    ADDR_SHIFT_AMOUNT: begin
                        s_axi_rdata <= {28'd0, reg_shift_amount};
                    end
                    ADDR_OUT_VALUE: begin
                        s_axi_rdata <= {16'd0, shifter_out_value};
                    end
                    default: begin
                        s_axi_rdata <= {DATA_WIDTH{1'b0}};
                    end
                endcase
                s_axi_rvalid <= 1'b1;
                s_axi_rresp  <= 2'b00;
            end else if (s_axi_rvalid && s_axi_rready) begin
                s_axi_rvalid <= 1'b0;
            end
        end
    end

    // Instantiate the parameterized shifter
    param_arith_shifter #(
        .IN_WIDTH (16),
        .SHIFT_WIDTH (4)
    ) shifter_core_inst (
        .in_value     (reg_in_value),
        .shift_amount (reg_shift_amount),
        .out_value    (shifter_out_value)
    );

endmodule

// Parameterized multi-stage arithmetic shifter module
module param_arith_shifter #(
    parameter IN_WIDTH = 16,
    parameter SHIFT_WIDTH = 4
)(
    input  [IN_WIDTH-1:0]  in_value,
    input  [SHIFT_WIDTH-1:0] shift_amount,
    output [IN_WIDTH-1:0]  out_value
);
    wire [IN_WIDTH-1:0] stage [SHIFT_WIDTH:0];

    assign stage[0] = in_value;

    genvar i;
    generate
        for (i = 0; i < SHIFT_WIDTH; i = i + 1) begin : SHIFT_STAGE
            assign stage[i+1] = shift_amount[SHIFT_WIDTH-1-i] ? 
                { { (1<<i) {stage[i][IN_WIDTH-1]} }, stage[i][IN_WIDTH-1: (1<<i)] } :
                stage[i];
        end
    endgenerate

    assign out_value = stage[SHIFT_WIDTH];
endmodule
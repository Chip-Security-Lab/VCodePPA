//SystemVerilog
// AXI4-Lite Top-level module for 8-bit LCG-based RNG with hierarchical structure
module rng_lcg_3_axi4lite #(
    parameter MULT = 8'd5,
    parameter INC  = 8'd1
)(
    // AXI4-Lite Slave Interface
    input            axi_aclk,
    input            axi_aresetn,
    // Write address channel
    input      [3:0] s_axi_awaddr,
    input            s_axi_awvalid,
    output reg       s_axi_awready,
    // Write data channel
    input      [7:0] s_axi_wdata,
    input      [0:0] s_axi_wstrb,
    input            s_axi_wvalid,
    output reg       s_axi_wready,
    // Write response channel
    output reg [1:0] s_axi_bresp,
    output reg       s_axi_bvalid,
    input            s_axi_bready,
    // Read address channel
    input      [3:0] s_axi_araddr,
    input            s_axi_arvalid,
    output reg       s_axi_arready,
    // Read data channel
    output reg [7:0] s_axi_rdata,
    output reg [1:0] s_axi_rresp,
    output reg       s_axi_rvalid,
    input            s_axi_rready
);

    // Address mapping
    localparam ADDR_RNG_STATE = 4'h0; // RNG state/address
    localparam ADDR_RNG_EN    = 4'h4; // RNG enable/address

    // Internal registers
    reg        rng_en_reg;
    wire [7:0] rng_next_value;
    wire [7:0] rng_current_value;

    // State register submodule instance
    rng_lcg_state_reg #(
        .INIT_VALUE(8'd7)
    ) state_reg_inst (
        .clk(axi_aclk),
        .en(rng_en_reg),
        .next_value(rng_next_value),
        .current_value(rng_current_value)
    );

    // LCG calculation submodule instance
    rng_lcg_lcg_core #(
        .MULT(MULT),
        .INC(INC)
    ) lcg_core_inst (
        .current_value(rng_current_value),
        .next_value(rng_next_value)
    );

    // AXI4-Lite write FSM
    reg aw_en;

    always @(posedge axi_aclk) begin
        if (!axi_aresetn) begin
            s_axi_awready <= 1'b0;
            s_axi_wready  <= 1'b0;
            aw_en         <= 1'b1;
        end else begin
            if (~s_axi_awready && s_axi_awvalid && s_axi_wvalid && aw_en) begin
                s_axi_awready <= 1'b1;
                s_axi_wready  <= 1'b1;
                aw_en         <= 1'b0;
            end else if (s_axi_bready && s_axi_bvalid) begin
                aw_en         <= 1'b1;
                s_axi_awready <= 1'b0;
                s_axi_wready  <= 1'b0;
            end else begin
                s_axi_awready <= 1'b0;
                s_axi_wready  <= 1'b0;
            end
        end
    end

    // AXI4-Lite write response logic
    always @(posedge axi_aclk) begin
        if (!axi_aresetn) begin
            s_axi_bvalid <= 1'b0;
            s_axi_bresp  <= 2'b00;
        end else begin
            if (s_axi_awready && s_axi_awvalid && ~s_axi_bvalid && s_axi_wready && s_axi_wvalid) begin
                s_axi_bvalid <= 1'b1;
                s_axi_bresp  <= 2'b00; // OKAY
            end else if (s_axi_bready && s_axi_bvalid) begin
                s_axi_bvalid <= 1'b0;
            end
        end
    end

    // AXI4-Lite read FSM
    always @(posedge axi_aclk) begin
        if (!axi_aresetn) begin
            s_axi_arready <= 1'b0;
            s_axi_rvalid  <= 1'b0;
            s_axi_rdata   <= 8'd0;
            s_axi_rresp   <= 2'b00;
        end else begin
            if (~s_axi_arready && s_axi_arvalid) begin
                s_axi_arready <= 1'b1;
            end else begin
                s_axi_arready <= 1'b0;
            end

            if (s_axi_arready && s_axi_arvalid && ~s_axi_rvalid) begin
                case (s_axi_araddr[3:0])
                    ADDR_RNG_STATE: s_axi_rdata <= rng_current_value;
                    ADDR_RNG_EN:    s_axi_rdata <= {7'd0, rng_en_reg};
                    default:        s_axi_rdata <= 8'd0;
                endcase
                s_axi_rvalid <= 1'b1;
                s_axi_rresp  <= 2'b00; // OKAY
            end else if (s_axi_rvalid && s_axi_rready) begin
                s_axi_rvalid <= 1'b0;
            end
        end
    end

    // Write logic for control registers
    always @(posedge axi_aclk) begin
        if (!axi_aresetn) begin
            rng_en_reg <= 1'b0;
        end else begin
            if (s_axi_awready && s_axi_awvalid && s_axi_wready && s_axi_wvalid) begin
                case (s_axi_awaddr[3:0])
                    ADDR_RNG_EN: begin
                        if (s_axi_wstrb[0])
                            rng_en_reg <= s_axi_wdata[0];
                    end
                    default: ;
                endcase
            end
        end
    end

endmodule

// -----------------------------------------------------------------------------
// Submodule: State Register
// Purpose  : Stores the current LCG state and updates it on enable
// -----------------------------------------------------------------------------
module rng_lcg_state_reg #(
    parameter INIT_VALUE = 8'd0
)(
    input            clk,
    input            en,
    input  [7:0]     next_value,
    output reg [7:0] current_value
);
    initial current_value = INIT_VALUE;
    always @(posedge clk) begin
        if (en)
            current_value <= next_value;
    end
endmodule

// -----------------------------------------------------------------------------
// Submodule: LCG Core
// Purpose  : Calculates the next LCG value using parameterized MULT and INC
// -----------------------------------------------------------------------------
module rng_lcg_lcg_core #(
    parameter MULT = 8'd5,
    parameter INC  = 8'd1
)(
    input  [7:0] current_value,
    output [7:0] next_value
);
    assign next_value = current_value * MULT + INC;
endmodule
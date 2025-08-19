//SystemVerilog
module DualModeIVMU_AXI4Lite #(
    parameter DIRECT_BASE = 32'hB000_0000,
    parameter VECTOR_BASE = 32'hB100_0000
)(
    input                   aclk,
    input                   aresetn,
    // AXI4-Lite Write Address Channel
    input       [3:0]       s_axi_awaddr,
    input                   s_axi_awvalid,
    output reg              s_axi_awready,
    // AXI4-Lite Write Data Channel
    input       [31:0]      s_axi_wdata,
    input       [3:0]       s_axi_wstrb,
    input                   s_axi_wvalid,
    output reg              s_axi_wready,
    // AXI4-Lite Write Response Channel
    output reg  [1:0]       s_axi_bresp,
    output reg              s_axi_bvalid,
    input                   s_axi_bready,
    // AXI4-Lite Read Address Channel
    input       [3:0]       s_axi_araddr,
    input                   s_axi_arvalid,
    output reg              s_axi_arready,
    // AXI4-Lite Read Data Channel
    output reg  [31:0]      s_axi_rdata,
    output reg  [1:0]       s_axi_rresp,
    output reg              s_axi_rvalid,
    input                   s_axi_rready,
    // External IRQ Inputs
    input       [7:0]       interrupt,
    input                   mode_sel, // 0=direct, 1=vectored
    // Optional: connect irq_ack to register write, or to a mapped address/bit
    output reg  [31:0]      isr_addr,
    output reg              irq_active
);

    // Internal registers mapped to AXI4-Lite
    reg [7:0]   irq_status_reg;
    reg [7:0]   irq_status_next;
    reg         irq_active_next;
    reg [31:0]  isr_addr_next;

    wire [7:0]  new_irq_vec;
    wire [2:0]  highest_irq_idx;
    wire        any_new_irq;

    // AXI4-Lite internal signals
    reg         aw_hs;
    reg         w_hs;
    reg         ar_hs;
    reg [3:0]   awaddr_reg;
    reg [3:0]   araddr_reg;

    // Registers for AXI4-Lite
    reg         irq_ack_reg;
    reg         irq_ack_pulse;

    // AXI4-Lite register map
    // 0x00: irq_status_reg (read-only)
    // 0x04: irq_ack        (write 1 to ack)
    // 0x08: isr_addr       (read-only)
    // 0x0C: irq_active     (read-only)
    // 0x10: mode_sel       (read/write)

    // Write handshake
    always @(posedge aclk or negedge aresetn) begin
        if (!aresetn) begin
            s_axi_awready <= 1'b0;
            s_axi_wready  <= 1'b0;
            awaddr_reg    <= 4'h0;
        end else begin
            // Address handshake
            if (~s_axi_awready && s_axi_awvalid) begin
                s_axi_awready <= 1'b1;
                awaddr_reg <= s_axi_awaddr[3:0];
            end else if (s_axi_awready && s_axi_wready && s_axi_wvalid && s_axi_awvalid) begin
                s_axi_awready <= 1'b0;
            end else if (s_axi_bvalid && s_axi_bready) begin
                s_axi_awready <= 1'b0;
            end else if (s_axi_awready && s_axi_wvalid && s_axi_wready) begin
                s_axi_awready <= 1'b0;
            end else if (s_axi_awready && ~s_axi_awvalid) begin
                s_axi_awready <= 1'b0;
            end

            // Data handshake
            if (~s_axi_wready && s_axi_wvalid) begin
                s_axi_wready <= 1'b1;
            end else if (s_axi_awready && s_axi_wready && s_axi_wvalid && s_axi_awvalid) begin
                s_axi_wready <= 1'b0;
            end else if (s_axi_bvalid && s_axi_bready) begin
                s_axi_wready <= 1'b0;
            end else if (s_axi_wready && s_axi_awvalid && s_axi_wvalid) begin
                s_axi_wready <= 1'b0;
            end else if (s_axi_wready && ~s_axi_wvalid) begin
                s_axi_wready <= 1'b0;
            end
        end
    end

    assign aw_hs = s_axi_awready & s_axi_awvalid;
    assign w_hs  = s_axi_wready  & s_axi_wvalid;

    // Write response
    always @(posedge aclk or negedge aresetn) begin
        if (!aresetn) begin
            s_axi_bvalid <= 1'b0;
            s_axi_bresp  <= 2'b00;
        end else begin
            if (aw_hs && w_hs) begin
                s_axi_bvalid <= 1'b1;
                s_axi_bresp  <= 2'b00; // OKAY
            end else if (s_axi_bvalid && s_axi_bready) begin
                s_axi_bvalid <= 1'b0;
            end
        end
    end

    // Read handshake
    always @(posedge aclk or negedge aresetn) begin
        if (!aresetn) begin
            s_axi_arready <= 1'b0;
            araddr_reg    <= 4'h0;
        end else begin
            if (~s_axi_arready && s_axi_arvalid) begin
                s_axi_arready <= 1'b1;
                araddr_reg <= s_axi_araddr[3:0];
            end else if (s_axi_rvalid && s_axi_rready) begin
                s_axi_arready <= 1'b0;
            end else if (s_axi_arready && ~s_axi_arvalid) begin
                s_axi_arready <= 1'b0;
            end
        end
    end

    assign ar_hs = s_axi_arready & s_axi_arvalid;

    // Read data channel
    always @(posedge aclk or negedge aresetn) begin
        if (!aresetn) begin
            s_axi_rvalid <= 1'b0;
            s_axi_rdata  <= 32'h0;
            s_axi_rresp  <= 2'b00;
        end else begin
            if (ar_hs) begin
                s_axi_rvalid <= 1'b1;
                s_axi_rresp  <= 2'b00; // OKAY
                case (araddr_reg[3:2])
                    2'b00: s_axi_rdata <= {24'h0, irq_status_reg}; // 0x00
                    2'b01: s_axi_rdata <= {31'h0, irq_ack_reg};   // 0x04
                    2'b10: s_axi_rdata <= isr_addr;               // 0x08
                    2'b11: s_axi_rdata <= {31'h0, irq_active};    // 0x0C
                    default: s_axi_rdata <= 32'h0;
                endcase
            end else if (s_axi_rvalid && s_axi_rready) begin
                s_axi_rvalid <= 1'b0;
            end
        end
    end

    // Write register logic
    always @(posedge aclk or negedge aresetn) begin
        if (!aresetn) begin
            irq_ack_reg <= 1'b0;
        end else begin
            if (aw_hs && w_hs) begin
                case (awaddr_reg[3:2])
                    2'b01: irq_ack_reg <= s_axi_wdata[0]; // 0x04, write 1 to ack
                    default: irq_ack_reg <= 1'b0;
                endcase
            end else begin
                irq_ack_reg <= 1'b0;
            end
        end
    end

    // Generate irq_ack pulse on write to 0x04 (bit 0)
    always @(posedge aclk or negedge aresetn) begin
        if (!aresetn) begin
            irq_ack_pulse <= 1'b0;
        end else begin
            irq_ack_pulse <= (aw_hs && w_hs && awaddr_reg[3:2] == 2'b01 && s_axi_wdata[0]);
        end
    end

    // Core IRQ logic
    assign new_irq_vec = interrupt & ~irq_status_reg;
    assign any_new_irq = |new_irq_vec;

    wire [2:0] highest_irq_index_wire;
    HighestPriorityEncoder u_highest_priority_encoder (
        .irq_vector(new_irq_vec),
        .irq_valid(any_new_irq),
        .irq_index(highest_irq_index_wire)
    );

    // Mode select register for AXI4-Lite (optional, could be mapped if needed)
    reg mode_sel_reg;
    always @(posedge aclk or negedge aresetn) begin
        if (!aresetn) begin
            mode_sel_reg <= 1'b0;
        end else if (aw_hs && w_hs && awaddr_reg[3:2] == 2'b10) begin
            mode_sel_reg <= s_axi_wdata[0];
        end else begin
            mode_sel_reg <= mode_sel;
        end
    end

    // Internal logic for next state
    always @(*) begin
        irq_status_next = irq_status_reg;
        irq_active_next = irq_active;
        isr_addr_next   = isr_addr;

        if (!aresetn) begin
            irq_status_next = 8'h0;
            irq_active_next = 1'b0;
            isr_addr_next   = 32'h0;
        end else if (irq_ack_pulse) begin
            irq_active_next = 1'b0;
        end else if (any_new_irq && !irq_active) begin
            irq_status_next = irq_status_reg | new_irq_vec;
            irq_active_next = 1'b1;
            if (mode_sel) begin // Vectored mode
                isr_addr_next = VECTOR_BASE + (highest_irq_index_wire << 3);
            end else begin // Direct mode
                isr_addr_next = DIRECT_BASE;
            end
        end
    end

    // Sequential logic block
    always @(posedge aclk or negedge aresetn) begin
        if (!aresetn) begin
            irq_status_reg <= 8'h0;
            irq_active <= 1'b0;
            isr_addr <= 32'h0;
        end else begin
            irq_status_reg <= irq_status_next;
            irq_active <= irq_active_next;
            isr_addr <= isr_addr_next;
        end
    end

endmodule

// Pure combinational logic module for priority encoding
module HighestPriorityEncoder(
    input  [7:0] irq_vector,
    input        irq_valid,
    output reg [2:0] irq_index
);
    always @(*) begin
        irq_index = 3'd0;
        if (irq_valid) begin
            casex (irq_vector)
                8'b1xxxxxxx: irq_index = 3'd7;
                8'b01xxxxxx: irq_index = 3'd6;
                8'b001xxxxx: irq_index = 3'd5;
                8'b0001xxxx: irq_index = 3'd4;
                8'b00001xxx: irq_index = 3'd3;
                8'b000001xx: irq_index = 3'd2;
                8'b0000001x: irq_index = 3'd1;
                8'b00000001: irq_index = 3'd0;
                default:     irq_index = 3'd0;
            endcase
        end else begin
            irq_index = 3'd0;
        end
    end
endmodule
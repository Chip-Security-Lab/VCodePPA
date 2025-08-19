//SystemVerilog
module basic_lfsr_rng_axi4lite #(
    parameter ADDR_WIDTH = 4
)(
    input  wire         ACLK,
    input  wire         ARESETn,

    // AXI4-Lite Write Address Channel
    input  wire [ADDR_WIDTH-1:0] AWADDR,
    input  wire                  AWVALID,
    output wire                  AWREADY,

    // AXI4-Lite Write Data Channel
    input  wire [15:0]           WDATA,
    input  wire [1:0]            WSTRB,
    input  wire                  WVALID,
    output wire                  WREADY,

    // AXI4-Lite Write Response Channel
    output wire [1:0]            BRESP,
    output wire                  BVALID,
    input  wire                  BREADY,

    // AXI4-Lite Read Address Channel
    input  wire [ADDR_WIDTH-1:0] ARADDR,
    input  wire                  ARVALID,
    output wire                  ARREADY,

    // AXI4-Lite Read Data Channel
    output wire [15:0]           RDATA,
    output wire [1:0]            RRESP,
    output wire                  RVALID,
    input  wire                  RREADY
);
    // LFSR core
    reg  [15:0] lfsr_reg;
    wire        feedback_bit;

    assign feedback_bit = (lfsr_reg[15] ^ lfsr_reg[13]) ^ (lfsr_reg[12] ^ lfsr_reg[10]);

    // AXI4-Lite interface logic
    // Address decode
    localparam LFSR_OUT_ADDR   = 4'h0;
    localparam LFSR_RST_ADDR   = 4'h4;

    reg  [ADDR_WIDTH-1:0] write_addr;
    reg                   write_addr_valid;
    reg                   write_data_valid;
    reg                   write_resp_valid;
    reg                   lfsr_enable;
    wire                  write_enable;

    reg  [ADDR_WIDTH-1:0] read_addr;
    reg                   read_addr_valid;
    reg                   read_data_valid;

    // Write address handshake
    assign AWREADY = ~write_addr_valid;
    always @(posedge ACLK or negedge ARESETn) begin
        if (!ARESETn) begin
            write_addr_valid <= 1'b0;
            write_addr <= {ADDR_WIDTH{1'b0}};
        end else if (AWREADY && AWVALID) begin
            write_addr <= AWADDR;
            write_addr_valid <= 1'b1;
        end else if (write_enable) begin
            write_addr_valid <= 1'b0;
        end
    end

    // Write data handshake
    assign WREADY = ~write_data_valid;
    always @(posedge ACLK or negedge ARESETn) begin
        if (!ARESETn) begin
            write_data_valid <= 1'b0;
        end else if (WREADY && WVALID) begin
            write_data_valid <= 1'b1;
        end else if (write_enable) begin
            write_data_valid <= 1'b0;
        end
    end

    // Write enable
    assign write_enable = write_addr_valid && write_data_valid;

    // Write response logic
    assign BRESP = 2'b00; // OKAY
    assign BVALID = write_resp_valid;
    always @(posedge ACLK or negedge ARESETn) begin
        if (!ARESETn)
            write_resp_valid <= 1'b0;
        else if (write_enable)
            write_resp_valid <= 1'b1;
        else if (write_resp_valid && BREADY)
            write_resp_valid <= 1'b0;
    end

    // LFSR enable: advance LFSR on read or write to LFSR_OUT_ADDR
    always @(posedge ACLK or negedge ARESETn) begin
        if (!ARESETn)
            lfsr_enable <= 1'b0;
        else if ((write_enable && (write_addr == LFSR_OUT_ADDR)) ||
                 (read_addr_valid && ARREADY && ARVALID && (ARADDR == LFSR_OUT_ADDR)))
            lfsr_enable <= 1'b1;
        else
            lfsr_enable <= 1'b0;
    end

    // Read address handshake
    assign ARREADY = ~read_addr_valid;
    always @(posedge ACLK or negedge ARESETn) begin
        if (!ARESETn) begin
            read_addr_valid <= 1'b0;
            read_addr <= {ADDR_WIDTH{1'b0}};
        end else if (ARREADY && ARVALID) begin
            read_addr <= ARADDR;
            read_addr_valid <= 1'b1;
        end else if (read_data_valid && RREADY) begin
            read_addr_valid <= 1'b0;
        end
    end

    // Read data logic
    assign RDATA = (read_addr == LFSR_OUT_ADDR) ? lfsr_reg : 16'h0000;
    assign RRESP = 2'b00; // OKAY
    assign RVALID = read_data_valid;
    always @(posedge ACLK or negedge ARESETn) begin
        if (!ARESETn)
            read_data_valid <= 1'b0;
        else if (read_addr_valid && ~read_data_valid)
            read_data_valid <= 1'b1;
        else if (read_data_valid && RREADY)
            read_data_valid <= 1'b0;
    end

    // 16-bit conditional negation subtractor function
    function [15:0] cond_invert_subtractor;
        input [15:0] minuend;
        input [15:0] subtrahend;
        reg   [15:0] subtrahend_inv;
        reg          carry_in;
        begin
            // Perform conditional inversion and addition
            subtrahend_inv = ~subtrahend;
            carry_in = 1'b1;
            cond_invert_subtractor = minuend + subtrahend_inv + carry_in;
        end
    endfunction

    // LFSR update logic with conditional inversion subtractor for reset
    always @(posedge ACLK or negedge ARESETn) begin
        if (!ARESETn)
            lfsr_reg <= 16'hACE1;
        else if (write_enable && (write_addr == LFSR_RST_ADDR))
            lfsr_reg <= cond_invert_subtractor(16'h0000, 16'h531F); // 0 - 0x531F = 0xACE1
        else if (lfsr_enable)
            lfsr_reg <= {lfsr_reg[14:0], feedback_bit};
    end

endmodule
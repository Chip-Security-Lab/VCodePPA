//SystemVerilog
module WallaceMultiplier8x8_Pipelined(
    input wire  ACLK,
    input wire  ARESETn,
    input [7:0] a,
    input [7:0] b,
    output [15:0] product
);

    wire [63:0] partial_products;
    genvar i, j;

    // Generate partial products
    for (i = 0; i < 8; i = i + 1) begin
        for (j = 0; j < 8; j = j + 1) begin
            assign partial_products[i * 8 + j] = a[i] & b[j];
        end
    end

    // Pipelined Stage 1: Partial Products to Stage 1 Reduction
    reg [63:0] stage1_sum_r;
    reg [63:0] stage1_carry_r;

    generate
        for (j = 0; j < 8; j = j + 1) begin : stage1_col
            wire [7:0] col_bits;
            assign col_bits = {partial_products[7*8+j], partial_products[6*8+j], partial_products[5*8+j], partial_products[4*8+j], partial_products[3*8+j], partial_products[2*8+j], partial_products[1*8+j], partial_products[0*8+j]};

            // Using compressors (3:2 compressors example)
            wire [1:0] s0, c0;
            wire [1:0] s1, c1;
            wire [1:0] s2, c2;
            wire [1:0] s3, c3;

            assign {c0, s0} = col_bits[2:0];
            assign {c1, s1} = col_bits[5:3];
            assign {c2, s2} = {col_bits[7], col_bits[6], s0[1]};
            assign {c3, s3} = {c0[1], c1[1], s1[1]};

            always @(posedge ACLK or negedge ARESETn) begin
                if (!ARESETn) begin
                    stage1_sum_r[j] <= 1'b0;
                    stage1_sum_r[j+8] <= 1'b0;
                    stage1_sum_r[j+16] <= 1'b0;
                    stage1_sum_r[j+24] <= 1'b0;
                    stage1_carry_r[j] <= 1'b0;
                    stage1_carry_r[j+8] <= 1'b0;
                    stage1_carry_r[j+16] <= 1'b0;
                    stage1_carry_r[j+24] <= 1'b0;
                end else begin
                    stage1_sum_r[j] <= s0[0];
                    stage1_sum_r[j+8] <= s1[0];
                    stage1_sum_r[j+16] <= s2[0];
                    stage1_sum_r[j+24] <= s3[0];
                    stage1_carry_r[j] <= c0[0];
                    stage1_carry_r[j+8] <= c1[0];
                    stage1_carry_r[j+16] <= c2[0];
                    stage1_carry_r[j+24] <= c3[0];
                end
            end
        end
    endgenerate

    // Pipelined Stage 2: Further Reduction
    reg [63:0] stage2_sum_r;
    reg [63:0] stage2_carry_r;

     generate
        for (j = 0; j < 16; j = j + 1) begin : stage2_col
            wire [2:0] col_bits;
            // Ensure j-1 is handled correctly, assuming stage1_carry[-1] is 0
            assign col_bits = {stage1_sum_r[j+8], stage1_sum_r[j], (j == 0) ? 1'b0 : stage1_carry_r[j-1]}; // Simplified column alignment

            wire [1:0] s, c;
            assign {c, s} = col_bits;

            always @(posedge ACLK or negedge ARESETn) begin
                if (!ARESETn) begin
                    stage2_sum_r[j] <= 1'b0;
                    stage2_carry_r[j] <= 1'b0;
                end else begin
                    stage2_sum_r[j] <= s[0];
                    stage2_carry_r[j] <= c[0];
                end
            end
        end
    endgenerate

    // Pipelined Stage 3: Final Addition
    reg [15:0] final_sum_r;

    always @(posedge ACLK or negedge ARESETn) begin
        if (!ARESETn) begin
            final_sum_r <= 16'b0;
        end else begin
            final_sum_r <= stage2_sum_r[15:0] + {stage2_carry_r[14:0], 1'b0}; // Simplified final addition
        end
    end

    assign product = final_sum_r;

endmodule

module HybridOR_AXI4_Lite (
    // Global signals
    input wire  ACLK,
    input wire  ARESETn,

    // AXI4-Lite Write Address Channel
    input wire  AWVALID,
    output wire AWREADY,
    input wire [3:0] AWADDR, // Assuming 4-bit address for simplicity (16 addresses)
    input wire [2:0] AWPROT,
    input wire  AWREGION,
    input wire  AWLOCK,
    input wire [3:0] AWCACHE,
    input wire [2:0] AWBURST,
    input wire [3:0] AWLEN,
    input wire [2:0] AWSIZE,
    input wire [1:0] AWQOS,

    // AXI4-Lite Write Data Channel
    input wire  WVALID,
    output wire WREADY,
    input wire [31:0] WDATA, // AXI4-Lite typically uses 32-bit data
    input wire [3:0] WSTRB,

    // AXI4-Lite Write Response Channel
    output wire BVALID,
    input wire  BREADY,
    output wire [1:0] BRESP,

    // AXI4-Lite Read Address Channel
    input wire  ARVALID,
    output wire ARREADY,
    input wire [3:0] ARADDR, // Assuming 4-bit address for simplicity
    input wire [2:0] ARPROT,
    input wire  ARREGION,
    input wire  ARLOCK,
    input wire [3:0] ARCACHE,
    input wire [2:0] ARBURST,
    input wire [3:0] ARLEN,
    input wire [2:0] ARSIZE,
    input wire [1:0] ARQOS,

    // AXI4-Lite Read Data Channel
    output wire RVALID,
    input wire  RREADY,
    output wire [31:0] RDATA, // AXI4-Lite typically uses 32-bit data
    output wire [1:0] RRESP

    // Original outputs are now internal or mapped to AXI RDATA
    // output [7:0] result // Mapped to RDATA
);

    // Internal registers for memory-mapped access
    reg [7:0] data_reg; // Corresponds to original 'data' input
    reg [1:0] sel_reg;  // Corresponds to original 'sel' input

    // Pipelined result register
    reg [7:0] hybrid_or_result_r;

    // AXI4-Lite state machines and handshake logic
    reg awready_i = 1'b0;
    reg wready_i = 1'b0;
    reg bvalid_i = 1'b0;
    reg arready_i = 1'b0;
    reg rvalid_i = 1'b0;
    reg [31:0] rdata_i = 32'b0;
    reg [1:0] bresp_i = 2'b0;
    reg [1:0] rresp_i = 2'b0;

    // Address decoding (simple mapping)
    localparam ADDR_DATA   = 4'h0; // Map data_reg to address 0
    localparam ADDR_SEL    = 4'h4; // Map sel_reg to address 4 (byte address)
    localparam ADDR_RESULT = 4'h8; // Map result to address 8 (byte address)

    // Instantiate the Pipelined WallaceMultiplier8x8
    wire [15:0] shift_amount_mult_product;
    wire [7:0] sel_extended;
    wire [7:0] const_2;

    assign sel_extended = {6'b0, sel_reg}; // Extend sel to 8 bits
    assign const_2 = 8'd2;

    WallaceMultiplier8x8_Pipelined shift_amount_mult (
        .ACLK(ACLK),
        .ARESETn(ARESETn),
        .a(sel_extended),
        .b(const_2),
        .product(shift_amount_mult_product)
    );

    // Pipelined shift amount
    reg [3:0] shift_amount_r;
    always @(posedge ACLK or negedge ARESETn) begin
        if (!ARESETn) begin
            shift_amount_r <= 4'b0;
        end else begin
            shift_amount_r <= shift_amount_mult_product[3:0];
        end
    end

    // Reimplement the original HybridOR logic using pipelined registers
    wire [7:0] shifted_mask;
    assign shifted_mask = 8'hFF << shift_amount_r;

    always @(posedge ACLK or negedge ARESETn) begin
        if (!ARESETn) begin
            hybrid_or_result_r <= 8'b0;
        end else begin
            hybrid_or_result_r <= data_reg | shifted_mask;
        end
    end


    // AXI4-Lite Write Address Channel
    always @(posedge ACLK or negedge ARESETn) begin
        if (!ARESETn) begin
            awready_i <= 1'b1; // Ready to accept address after reset
        end else begin
            if (AWVALID && awready_i) begin
                awready_i <= 1'b0; // Address accepted, wait for data
            end else if (WVALID && wready_i && AWVALID && awready_i) begin
                // Simultaneous address and data valid (possible in AXI4-Lite)
                awready_i <= 1'b0; // Address accepted
            end else if (BVALID && BREADY) begin
                 awready_i <= 1'b1; // Ready for next transaction after response
            end
        end
    end

    assign AWREADY = awready_i;

    // AXI4-Lite Write Data Channel and Write Response Channel
    always @(posedge ACLK or negedge ARESETn) begin
        if (!ARESETn) begin
            wready_i <= 1'b0; // Start not ready for data until address
            bvalid_i <= 1'b0;
            bresp_i  <= 2'b0;
        end else begin
            // Handle Write
            if (AWVALID && awready_i && WVALID && wready_i) begin // Both address and data valid
                // Write operation
                case (AWADDR)
                    ADDR_DATA: begin
                        if (WSTRB[0]) data_reg[7:0] <= WDATA[7:0]; // Assuming byte access for 8-bit data
                    end
                    ADDR_SEL: begin
                        if (WSTRB[0]) sel_reg[1:0] <= WDATA[1:0]; // Assuming byte access for 2-bit sel
                    end
                    default: begin
                        // Ignore write to other addresses
                    end
                endcase
                bvalid_i <= 1'b1; // Write complete, assert BVALID
                bresp_i  <= 2'b0; // OKAY response
                wready_i <= 1'b0; // Data accepted
            end else if (WVALID && wready_i && !AWVALID) begin
                 // Data received without a preceding address (shouldn't happen in strict AXI4-Lite)
                 // Handle as an error or ignore
                 bvalid_i <= 1'b1; // Indicate response needed
                 bresp_i  <= 2'b1; // SLVERR response
                 wready_i <= 1'b0; // Data accepted (to clear the handshake)
            end else if (AWVALID && awready_i && !WVALID) begin
                 // Address received, waiting for data
                 wready_i <= 1'b1; // Ready to accept data
            end else if (BVALID && BREADY) begin
                bvalid_i <= 1'b0; // Response handshake complete
            end
        end
    end

    assign WREADY = wready_i;
    assign BVALID = bvalid_i;
    assign BRESP  = bresp_i;


    // AXI4-Lite Read Address Channel and Read Data Channel
    always @(posedge ACLK or negedge ARESETn) begin
        if (!ARESETn) begin
            arready_i <= 1'b1; // Ready to accept address after reset
            rvalid_i  <= 1'b0;
            rdata_i   <= 32'b0;
            rresp_i   <= 2'b0;
        end else begin
            // Handle Read
            if (ARVALID && arready_i) begin
                // Address accepted, prepare data
                case (ARADDR)
                    ADDR_DATA: begin
                        rdata_i <= {24'b0, data_reg}; // Return data_reg
                        rresp_i <= 2'b0; // OKAY
                    end
                    ADDR_SEL: begin
                        rdata_i <= {30'b0, sel_reg}; // Return sel_reg
                        rresp_i <= 2'b0; // OKAY
                    end
                    ADDR_RESULT: begin
                        rdata_i <= {24'b0, hybrid_or_result_r}; // Return the result
                        rresp_i <= 2'b0; // OKAY
                    end
                    default: begin
                        rdata_i <= 32'b0; // Return zero for unmapped addresses
                        rresp_i <= 2'b1; // SLVERR
                    end
                endcase
                arready_i <= 1'b0; // Address accepted, wait for data to be read
                rvalid_i  <= 1'b1; // Data is valid
            end else if (RVALID && RREADY) begin
                // Data handshake complete
                rvalid_i <= 1'b0; // Data is no longer valid
                arready_i <= 1'b1; // Ready for next read address
            end
        end
    end

    assign ARREADY = arready_i;
    assign RVALID  = rvalid_i;
    assign RDATA   = rdata_i;
    assign RRESP   = rresp_i;

endmodule
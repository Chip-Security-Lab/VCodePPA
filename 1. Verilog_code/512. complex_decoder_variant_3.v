module complex_decoder_axi4lite (
    // AXI4-Lite Global Signals
    input wire ACLK,
    input wire ARESETn,
    
    // AXI4-Lite Write Address Channel
    input wire [31:0] AWADDR,
    input wire AWVALID,
    output wire AWREADY,
    
    // AXI4-Lite Write Data Channel
    input wire [31:0] WDATA,
    input wire [3:0] WSTRB,
    input wire WVALID,
    output wire WREADY,
    
    // AXI4-Lite Write Response Channel
    output wire [1:0] BRESP,
    output wire BVALID,
    input wire BREADY,
    
    // AXI4-Lite Read Address Channel
    input wire [31:0] ARADDR,
    input wire ARVALID,
    output wire ARREADY,
    
    // AXI4-Lite Read Data Channel
    output wire [31:0] RDATA,
    output wire [1:0] RRESP,
    output wire RVALID,
    input wire RREADY
);

    // Internal registers
    reg [7:0] dec_reg;
    reg [1:0] ab_comb_reg;
    reg [3:0] dec_low_reg;
    reg [3:0] dec_high_reg;
    
    // AXI4-Lite control signals
    reg awready_reg;
    reg wready_reg;
    reg bvalid_reg;
    reg arready_reg;
    reg rvalid_reg;
    
    // Write address channel
    assign AWREADY = awready_reg;
    always @(posedge ACLK or negedge ARESETn) begin
        if (!ARESETn) begin
            awready_reg <= 1'b0;
        end else begin
            awready_reg <= !awready_reg && AWVALID;
        end
    end
    
    // Write data channel
    assign WREADY = wready_reg;
    always @(posedge ACLK or negedge ARESETn) begin
        if (!ARESETn) begin
            wready_reg <= 1'b0;
        end else begin
            wready_reg <= !wready_reg && WVALID;
        end
    end
    
    // Write response channel
    assign BVALID = bvalid_reg;
    assign BRESP = 2'b00; // OKAY response
    always @(posedge ACLK or negedge ARESETn) begin
        if (!ARESETn) begin
            bvalid_reg <= 1'b0;
        end else begin
            bvalid_reg <= (awready_reg && wready_reg) ? 1'b1 : 
                         (BREADY && bvalid_reg) ? 1'b0 : bvalid_reg;
        end
    end
    
    // Read address channel
    assign ARREADY = arready_reg;
    always @(posedge ACLK or negedge ARESETn) begin
        if (!ARESETn) begin
            arready_reg <= 1'b0;
        end else begin
            arready_reg <= !arready_reg && ARVALID;
        end
    end
    
    // Read data channel
    assign RVALID = rvalid_reg;
    assign RRESP = 2'b00; // OKAY response
    assign RDATA = {24'b0, dec_reg};
    always @(posedge ACLK or negedge ARESETn) begin
        if (!ARESETn) begin
            rvalid_reg <= 1'b0;
        end else begin
            rvalid_reg <= (arready_reg) ? 1'b1 : 
                         (RREADY && rvalid_reg) ? 1'b0 : rvalid_reg;
        end
    end
    
    // Core decoder logic
    always @(posedge ACLK or negedge ARESETn) begin
        if (!ARESETn) begin
            ab_comb_reg <= 2'b00;
            dec_low_reg <= 4'b0000;
            dec_high_reg <= 4'b0000;
            dec_reg <= 8'b00000000;
        end else if (WVALID && WREADY) begin
            // Update internal registers based on WDATA
            ab_comb_reg[0] <= ~WDATA[0] & ~WDATA[1];
            ab_comb_reg[1] <= WDATA[0] & WDATA[1];
            
            dec_low_reg[0] <= ab_comb_reg[0] & ~WDATA[2];
            dec_low_reg[1] <= ab_comb_reg[0] & WDATA[2];
            dec_low_reg[2] <= ~ab_comb_reg[0] & ~ab_comb_reg[1] & ~WDATA[2];
            dec_low_reg[3] <= ~ab_comb_reg[0] & ~ab_comb_reg[1] & WDATA[2];
            
            dec_high_reg[0] <= ~ab_comb_reg[0] & ~ab_comb_reg[1] & ~WDATA[2];
            dec_high_reg[1] <= ~ab_comb_reg[0] & ~ab_comb_reg[1] & WDATA[2];
            dec_high_reg[2] <= ab_comb_reg[1] & ~WDATA[2];
            dec_high_reg[3] <= ab_comb_reg[1] & WDATA[2];
            
            dec_reg <= {dec_high_reg, dec_low_reg};
        end
    end

endmodule
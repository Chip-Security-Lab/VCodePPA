//SystemVerilog
module PartialNOT_axi_lite_pipelined (
    input wire  aclk,
    input wire  aresetn,

    // AXI4-Lite Write Channel
    input wire  awvalid,
    output wire awready,
    input wire [3:0] awaddr,
    input wire  wvalid,
    output wire wready,
    input wire [31:0] wdata,
    input wire [3:0] wstrb,
    output wire bvalid,
    input wire  bready,
    output wire [1:0] bresp,

    // AXI4-Lite Read Channel
    input wire  arvalid,
    output wire arready,
    input wire [3:0] araddr,
    output wire rvalid,
    input wire  rready,
    output wire [31:0] rdata,
    output wire [1:0] rresp
);

// --- Write Channel Pipeline ---
// Stage 0: AXI Write Address and Data Handshake
reg aw_hs_s0;
reg w_hs_s0;
reg [3:0] awaddr_s0;
reg [31:0] wdata_s0;
reg [3:0] wstrb_s0;

assign awready = ~aw_hs_s0 & awvalid;
assign wready = ~w_hs_s0 & wvalid;

always @(posedge aclk) begin
    if (~aresetn) begin
        aw_hs_s0 <= 1'b0;
        w_hs_s0 <= 1'b0;
        awaddr_s0 <= 4'b0;
        wdata_s0 <= 32'b0;
        wstrb_s0 <= 4'b0;
    end else begin
        // Capture handshake signals and data/address
        if (awvalid & awready) begin
            aw_hs_s0 <= 1'b1;
            awaddr_s0 <= awaddr;
        end else if (~(bvalid & bready)) begin // Clear handshake after B response
             aw_hs_s0 <= 1'b0;
        end

        if (wvalid & wready) begin
            w_hs_s0 <= 1'b1;
            wdata_s0 <= wdata;
            wstrb_s0 <= wstrb;
        end else if (~(bvalid & bready)) begin // Clear handshake after B response
             w_hs_s0 <= 1'b0;
        end
    end
end

// Stage 1: Write Data to Register
reg aw_hs_s1;
reg w_hs_s1;
reg [3:0] awaddr_s1;
reg [31:0] wdata_s1;
reg [3:0] wstrb_s1;
reg [15:0] word_reg; // The actual data register

always @(posedge aclk) begin
    if (~aresetn) begin
        aw_hs_s1 <= 1'b0;
        w_hs_s1 <= 1'b0;
        awaddr_s1 <= 4'b0;
        wdata_s1 <= 32'b0;
        wstrb_s1 <= 4'b0;
        word_reg <= 16'b0;
    end else begin
        // Pass handshake and data/address to stage 1
        aw_hs_s1 <= aw_hs_s0;
        w_hs_s1 <= w_hs_s0;
        awaddr_s1 <= awaddr_s0;
        wdata_s1 <= wdata_s0;
        wstrb_s1 <= wstrb_s0;

        // Perform the write operation in stage 1
        if (aw_hs_s0 & w_hs_s0) begin
            // Simple memory mapping: address 0 is the input word register
            if (awaddr_s0 == 4'd0) begin
                // Assuming 16-bit data is written to the lower 16 bits of the 32-bit AXI data bus
                if (wstrb_s0[1]) word_reg[15:8] <= wdata_s0[15:8];
                if (wstrb_s0[0]) word_reg[7:0] <= wdata_s0[7:0];
            end
        end
    end
end

// Stage 2: B Response
assign bvalid = aw_hs_s1 & w_hs_s1; // Bvalid is ready when write is complete
assign bresp = 2'b00; // OKAY response


// --- Read Channel Pipeline ---
// Stage 0: AXI Read Address Handshake
reg ar_hs_s0;
reg [3:0] araddr_s0;

assign arready = ~ar_hs_s0 & arvalid;

always @(posedge aclk) begin
    if (~aresetn) begin
        ar_hs_s0 <= 1'b0;
        araddr_s0 <= 4'b0;
    end else begin
        // Capture handshake signal and address
        if (arvalid & arready) begin
            ar_hs_s0 <= 1'b1;
            araddr_s0 <= araddr;
        end else if (~(rvalid & rready)) begin // Clear handshake after R response
            ar_hs_s0 <= 1'b0;
        end
    end
end

// Stage 1: Read Data Calculation
reg ar_hs_s1;
reg [3:0] araddr_s1;
reg [31:0] read_data_s1;
wire [15:0] modified_wire_s1; // Combinational logic for modification

// Original PartialNOT logic (combinational)
assign modified_wire_s1[15:8] = word_reg[15:8];  // High byte remains
assign modified_wire_s1[7:0] = ~word_reg[7:0];   // Low byte inverted


always @(posedge aclk) begin
    if (~aresetn) begin
        ar_hs_s1 <= 1'b0;
        araddr_s1 <= 4'b0;
        read_data_s1 <= 32'b0;
    end else begin
        // Pass handshake and address to stage 1
        ar_hs_s1 <= ar_hs_s0;
        araddr_s1 <= araddr_s0;

        // Perform data read/calculation in stage 1
        if (ar_hs_s0) begin
            // Simple memory mapping: address 0 is the input word, address 4 is the modified word
            case (araddr_s0)
                4'd0: begin
                    read_data_s1[15:0] <= word_reg;
                    read_data_s1[31:16] <= 16'b0; // Upper bits are zero
                end
                4'd4: begin
                    read_data_s1[15:0] <= modified_wire_s1; // Use the combinational result
                    read_data_s1[31:16] <= 16'b0; // Upper bits are zero
                end
                default: begin
                    read_data_s1 <= 32'b0; // Read 0 for invalid addresses
                end
            endcase
        end
    end
end

// Stage 2: R Response
reg ar_hs_s2;
reg [31:0] rdata_s2;

assign rvalid = ar_hs_s2; // Rvalid is ready when read data is available
assign rresp = 2'b00; // OKAY response
assign rdata = rdata_s2;

always @(posedge aclk) begin
    if (~aresetn) begin
        ar_hs_s2 <= 1'b0;
        rdata_s2 <= 32'b0;
    end else begin
        // Pass handshake and data to stage 2
        ar_hs_s2 <= ar_hs_s1;
        rdata_s2 <= read_data_s1;
    end
end


endmodule
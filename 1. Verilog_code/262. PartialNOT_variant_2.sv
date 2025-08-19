//SystemVerilog
// SystemVerilog

// Submodule for AXI4-Lite Write Channel Logic
module AXI4_Lite_Write_Channel (
    input wire clk,
    input wire resetn,

    input wire [3:0] awaddr,
    input wire awvalid,
    output wire awready,

    input wire [31:0] wdata,
    input wire [3:0] wstrb,
    input wire wvalid,
    output wire wready,

    output wire [1:0] bresp,
    output wire bvalid,
    input wire bready,

    output wire [15:0] data_write, // Data to be written to the register
    output wire [1:0] data_write_strb, // Byte enables for the write
    output wire data_write_en // Enable signal for writing to the register
);

reg awready_reg;
reg wready_reg;
reg bvalid_reg;
reg [1:0] bresp_reg;

assign awready = awready_reg;
assign wready = wready_reg;
assign bvalid = bvalid_reg;
assign bresp = bresp_reg;

reg [15:0] data_write_reg;
reg [1:0] data_write_strb_reg;
reg data_write_en_reg;

assign data_write = data_write_reg;
assign data_write_strb = data_write_strb_reg;
assign data_write_en = data_write_en_reg;

always @(posedge clk or negedge resetn) begin
    if (!resetn) begin
        awready_reg <= 1'b0;
        wready_reg <= 1'b0;
        bvalid_reg <= 1'b0;
        bresp_reg <= 2'b00;
        data_write_en_reg <= 1'b0;
        data_write_reg <= 16'b0;
        data_write_strb_reg <= 2'b00;
    end else begin
        data_write_en_reg <= 1'b0; // Default to no write

        // AW channel handshake
        if (awvalid && !awready_reg) begin
            awready_reg <= 1'b1;
        end else if (awready_reg && wvalid && wready_reg) begin // Complete write transaction
             awready_reg <= 1'b0;
        end

        // W channel handshake and data write
        if (awready_reg && awvalid && wvalid && !wready_reg) begin
            wready_reg <= 1'b1;
             // Assume address 0x00 maps to the 16-bit data
            if (awaddr == 4'h0) begin
                data_write_reg[15:8] <= wdata[15:8];
                data_write_reg[7:0] <= wdata[7:0];
                data_write_strb_reg[1] <= wstrb[1];
                data_write_strb_reg[0] <= wstrb[0];
                data_write_en_reg <= 1'b1;
            end
        end else if (wready_reg && bready) begin // Complete write transaction
            wready_reg <= 1'b0;
        end else if (wvalid && wready_reg && !awvalid) begin // Handle W before AW (though not standard AXI)
             wready_reg <= 1'b0;
        end

        // B channel handshake
        if (awready_reg && awvalid && wready_reg && wvalid && !bvalid_reg) begin
            bvalid_reg <= 1'b1;
            bresp_reg <= 2'b00; // OKAY response
        end else if (bvalid_reg && bready) begin
            bvalid_reg <= 1'b0;
        end
    end
end

endmodule


// Submodule for AXI4-Lite Read Channel Logic
module AXI4_Lite_Read_Channel (
    input wire clk,
    input wire resetn,

    input wire [3:0] araddr,
    input wire arvalid,
    output wire arready,

    output wire [31:0] rdata,
    output wire [1:0] rresp,
    output wire rvalid,
    input wire rready,

    input wire [15:0] data_read // Data to be read from the register
);

reg arready_reg;
reg rvalid_reg;
reg [31:0] rdata_reg;
reg [1:0] rresp_reg;

assign arready = arready_reg;
assign rvalid = rvalid_reg;
assign rdata = rdata_reg;
assign rresp = rresp_reg;

always @(posedge clk or negedge resetn) begin
    if (!resetn) begin
        arready_reg <= 1'b0;
        rvalid_reg <= 1'b0;
        rdata_reg <= 32'b0;
        rresp_reg <= 2'b00;
    end else begin
        // AR channel handshake
        if (arvalid && !arready_reg) begin
            arready_reg <= 1'b1;
        end else if (arready_reg && rvalid_reg && rready) begin // Complete read transaction
            arready_reg <= 1'b0;
        end

        // R channel handshake and data read
        if (arvalid && arready_reg && !rvalid_reg) begin
            rvalid_reg <= 1'b1;
            // Assume address 0x00 maps to the 16-bit data
            if (araddr == 4'h0) begin
                rresp_reg <= 2'b00; // OKAY response
                 // Apply the original logic: high byte unchanged, low byte inverted
                rdata_reg[31:16] <= 16'b0; // Pad upper bits
                rdata_reg[15:8] <= data_read[15:8];  // High byte unchanged
                rdata_reg[7:0] <= ~data_read[7:0];   // Low byte inverted
            end else begin
                 rdata_reg <= 32'b0; // Default to 0 for invalid addresses
                 rresp_reg <= 2'b10; // SLVERR response for invalid address
                 rvalid_reg <= 1'b1; // Set rvalid even for error
            end
        end else if (rvalid_reg && rready) begin
            rvalid_reg <= 1'b0;
        end
    end
end

endmodule


// Top-level module
module PartialNOT_AXI4_Lite (
    input wire clk,
    input wire resetn,

    // AXI4-Lite Write Address Channel
    input wire [3:0] awaddr,
    input wire awvalid,
    output wire awready,

    // AXI4-Lite Write Data Channel
    input wire [31:0] wdata,
    input wire [3:0] wstrb,
    input wire wvalid,
    output wire wready,

    // AXI4-Lite Write Response Channel
    output wire [1:0] bresp,
    output wire bvalid,
    input wire bready,

    // AXI4-Lite Read Address Channel
    input wire [3:0] araddr,
    input wire arvalid,
    output wire arready,

    // AXI4-Lite Read Data Channel
    output wire [31:0] rdata,
    output wire [1:0] rresp,
    output wire rvalid,
    input wire rready
);

// Internal Register
reg [15:0] data_reg; // Register to hold the 16-bit data

// Signals connecting submodules
wire [15:0] write_data;
wire [1:0] write_strb;
wire write_en;

// Instantiate Write Channel Submodule
AXI4_Lite_Write_Channel write_channel_inst (
    .clk(clk),
    .resetn(resetn),
    .awaddr(awaddr),
    .awvalid(awvalid),
    .awready(awready),
    .wdata(wdata),
    .wstrb(wstrb),
    .wvalid(wvalid),
    .wready(wready),
    .bresp(bresp),
    .bvalid(bvalid),
    .bready(bready),
    .data_write(write_data),
    .data_write_strb(write_strb),
    .data_write_en(write_en)
);

// Instantiate Read Channel Submodule
AXI4_Lite_Read_Channel read_channel_inst (
    .clk(clk),
    .resetn(resetn),
    .araddr(araddr),
    .arvalid(arvalid),
    .arready(arready),
    .rdata(rdata),
    .rresp(rresp),
    .rvalid(rvalid),
    .rready(rready),
    .data_read(data_reg) // Connect the register value for reading
);

// Logic for the internal register
always @(posedge clk or negedge resetn) begin
    if (!resetn) begin
        data_reg <= 16'b0;
    end else begin
        if (write_en) begin
            if (write_strb[1]) data_reg[15:8] <= write_data[15:8]; // Write high byte
            if (write_strb[0]) data_reg[7:0] <= write_data[7:0];   // Write low byte
        end
    end
end

endmodule
//SystemVerilog
module not_gate_axi4lite (
    input wire clk,
    input wire reset,

    // AXI4-Lite Read Address Channel
    input wire [3:0]  awaddr,
    input wire        awvalid,
    output wire       awready,

    // AXI4-Lite Write Data Channel
    input wire [31:0] wdata,
    input wire [3:0]  wstrb,
    input wire        wvalid,
    output wire       wready,

    // AXI4-Lite Write Response Channel
    input wire        bready,
    output wire [1:0] bresp,
    output wire       bvalid,

    // AXI4-Lite Read Address Channel
    input wire [3:0]  araddr,
    input wire        arvalid,
    output wire       arready,

    // AXI4-Lite Read Data Channel
    input wire        rready,
    output wire [31:0] rdata,
    output wire [1:0] rresp,
    output wire       rvalid
);

    // Internal registers for not gate logic
    reg  input_data_reg;
    reg  output_data_reg;

    // AXI4-Lite internal signals
    reg  awready_reg;
    reg  wready_reg;
    reg  bvalid_reg;
    reg  [1:0] bresp_reg;

    reg  arready_reg;
    reg  rvalid_reg;
    reg  [31:0] rdata_reg;
    reg  [1:0] rresp_reg;

    // Assign outputs
    assign awready = awready_reg;
    assign wready  = wready_reg;
    assign bvalid  = bvalid_reg;
    assign bresp   = bresp_reg;

    assign arready = arready_reg;
    assign rvalid  = rvalid_reg;
    assign rdata   = rdata_reg;
    assign rresp   = rresp_reg;

    // Address mapping
    localparam ADDR_INPUT_DATA  = 4'h0; // Address for input data (write)
    localparam ADDR_OUTPUT_DATA = 4'h4; // Address for output data (read)

    always @(posedge clk or posedge reset) begin
        if (reset) begin
            awready_reg   <= 1'b1;
            wready_reg    <= 1'b1;
            bvalid_reg    <= 1'b0;
            bresp_reg     <= 2'b00; // OKAY

            arready_reg   <= 1'b1;
            rvalid_reg    <= 1'b0;
            rdata_reg     <= 32'h0;
            rresp_reg     <= 2'b00; // OKAY

            input_data_reg <= 1'b0;
            output_data_reg <= 1'b0;

        end else begin
            // Default to not ready/valid
            awready_reg <= 1'b0;
            wready_reg  <= 1'b0;
            bvalid_reg  <= 1'b0;
            bresp_reg   <= 2'b00; // OKAY

            arready_reg <= 1'b0;
            rvalid_reg  <= 1'b0;
            rdata_reg   <= 32'h0;
            rresp_reg   <= 2'b00; // OKAY

            // Write transaction
            if (awvalid && awready_reg) begin
                // Address phase accepted
                awready_reg <= 1'b0; // Not ready for next address until write data is handled
                if (awaddr == ADDR_INPUT_DATA) begin
                    wready_reg <= 1'b1; // Ready for write data
                end else begin
                    // Invalid address, still need to accept data to complete transaction
                    wready_reg <= 1'b1;
                end
            end else if (!awvalid && !awready_reg) begin
                 // Ready for next address if no transaction is ongoing
                 if (!wvalid && !bvalid_reg) begin
                     awready_reg <= 1'b1;
                 end
            end else if (awvalid && !awready_reg) begin
                // Keep awready low if address is valid but not ready
                awready_reg <= 1'b0;
            end else if (!awvalid && awready_reg) begin
                 // Stay ready if no address valid
                 awready_reg <= 1'b1;
            end


            if (wvalid && wready_reg) begin
                // Data phase accepted
                wready_reg <= 1'b0; // Not ready for next data
                bvalid_reg <= 1'b1; // Write response is ready

                // Process write data based on the accepted address
                if (awaddr == ADDR_INPUT_DATA) begin
                    // Assuming wdata[0] holds the single bit input
                    input_data_reg <= wdata[0];
                    output_data_reg <= ~wdata[0]; // Perform the not operation
                    bresp_reg <= 2'b00; // OKAY
                end else begin
                    // Invalid address write
                    bresp_reg <= 2'b10; // SLVERR
                end
            end else if (!wvalid && !wready_reg) begin
                 // Ready for next data if address was accepted and no data is pending
                 if (!awvalid && !bvalid_reg) begin
                     wready_reg <= 1'b1;
                 end
            end else if (wvalid && !wready_reg) begin
                // Keep wready low if data is valid but not ready
                wready_reg <= 1'b0;
            end else if (!wvalid && wready_reg) begin
                 // Stay ready if no data valid
                 wready_reg <= 1'b1;
            end


            if (bvalid_reg && bready) begin
                // Write response consumed
                bvalid_reg <= 1'b0;
                // Ready for the next write transaction
                awready_reg <= 1'b1;
                wready_reg <= 1'b1;
            end

            // Read transaction
            if (arvalid && arready_reg) begin
                // Address phase accepted
                arready_reg <= 1'b0; // Not ready for next address until read data is sent
                rvalid_reg <= 1'b1; // Read data is ready

                // Provide read data based on the accepted address
                if (araddr == ADDR_OUTPUT_DATA) begin
                    rdata_reg <= {31'h0, output_data_reg}; // Output data
                    rresp_reg <= 2'b00; // OKAY
                end else begin
                    // Invalid address read
                    rdata_reg <= 32'h0; // Default value for invalid address
                    rresp_reg <= 2'b10; // SLVERR
                end
            end else if (!arvalid && !arready_reg) begin
                 // Ready for next address if no transaction is ongoing
                 if (!rvalid_reg) begin
                     arready_reg <= 1'b1;
                 end
            end else if (arvalid && !arready_reg) begin
                // Keep arready low if address is valid but not ready
                arready_reg <= 1'b0;
            end else if (!arvalid && arready_reg) begin
                 // Stay ready if no address valid
                 arready_reg <= 1'b1;
            end


            if (rvalid_reg && rready) begin
                // Read data consumed
                rvalid_reg <= 1'b0;
                // Ready for the next read transaction
                arready_reg <= 1'b1;
            end

            // Handle cases where AWREADY/WREADY/ARREADY should be high when no transaction is in progress
            if (!awvalid && !wvalid && !bvalid_reg && !arvalid && !rvalid_reg) begin
                awready_reg <= 1'b1;
                wready_reg <= 1'b1;
                arready_reg <= 1'b1;
            end

        end
    end

endmodule
//SystemVerilog
module ArrayOR_AXI4_Lite (
    input wire  aclk,
    input wire  aresetn,

    // AXI4-Lite Read Address Channel
    input wire  [3:0] awaddr,
    input wire  awvalid,
    output wire awready,

    // AXI4-Lite Write Data Channel
    input wire  [7:0] wdata,
    input wire  wvalid,
    output wire wready,

    // AXI4-Lite Write Response Channel
    output wire [1:0] bresp,
    output wire bvalid,
    input wire  bready,

    // AXI4-Lite Read Address Channel
    input wire  [3:0] araddr,
    input wire  arvalid,
    output wire arready,

    // AXI4-Lite Read Data Channel
    output wire [7:0] rdata,
    output wire [1:0] rresp,
    output wire rvalid,
    input wire  rready
);

    // Internal signals and registers
    reg [7:0] matrix_or_reg;
    reg awready_reg;
    reg wready_reg;
    reg bvalid_reg;
    reg arready_reg;
    reg rvalid_reg;
    reg [7:0] read_data_reg;

    // AXI4-Lite Write Channel
    assign awready = awready_reg;
    assign wready  = wready_reg;
    assign bresp   = 2'b00; // OKAY response
    assign bvalid  = bvalid_reg;

    always @(posedge aclk or negedge aresetn) begin
        if (!aresetn) begin
            awready_reg <= 1'b0;
            wready_reg  <= 1'b0;
            bvalid_reg  <= 1'b0;
            matrix_or_reg <= 8'h00;
        end else begin
            // Write Address Channel
            awready_reg <= awvalid && !awready_reg;

            // Write Data Channel
            wready_reg <= wvalid && !wready_reg;

            // Write Response Channel
            bvalid_reg <= (awvalid && awready_reg && wvalid && wready_reg) || (bvalid_reg && !bready);

            // Handle write data and logic
            if (wvalid && wready_reg && awaddr == 4'h0) begin
                 matrix_or_reg <= wdata | 8'hAA;
            end
        end
    end

    // AXI4-Lite Read Channel
    assign arready = arready_reg;
    assign rdata   = read_data_reg;
    assign rresp   = 2'b00; // OKAY response
    assign rvalid  = rvalid_reg;

    always @(posedge aclk or negedge aresetn) begin
        if (!aresetn) begin
            arready_reg   <= 1'b0;
            rvalid_reg    <= 1'b0;
            read_data_reg <= 8'h00;
        end else begin
            // Read Address Channel
            arready_reg <= arvalid && !arready_reg;

            // Read Data Channel
            rvalid_reg <= (arvalid && arready_reg) || (rvalid_reg && !rready);

            // Handle read data
            if (arvalid && arready_reg && araddr == 4'h0) begin
                read_data_reg <= matrix_or_reg;
            end
        end
    end

    // Core logic (simplified - the original logic is now accessed via AXI)
    // The original logic "assign matrix_or = {row, col} | 8'hAA;"
    // is now implicitly handled by writing to and reading from matrix_or_reg
    // where the write data effectively represents the combined {row, col} and the read
    // data represents the result of the OR operation with 8'hAA.
    // To maintain the original functionality, we'll perform the OR operation
    // on the data written to the register.
    // The OR operation is now integrated into the write data handling.

endmodule